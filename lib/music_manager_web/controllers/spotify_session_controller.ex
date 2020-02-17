defmodule MusicManagerWeb.SpotifySessionController do
  use MusicManagerWeb, :controller
  alias MusicManager.Integrations
  alias MusicManager.Repo
  import MusicManagerWeb.Plugs.Auth, only: [authenticate_user: 2]

  plug :authenticate_user

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, _) do
    spotify_client_id = Application.fetch_env!(:music_manager, :spotify_client_id)
    spotify_secret_key = Application.fetch_env!(:music_manager, :spotify_secret_key)
    spotify_scope = Application.fetch_env!(:music_manager, :spotify_scope)
    redirect_uri = Application.fetch_env!(:music_manager, :redirect_uri)

    # todo: change state param
    spotify_oauth_url =
      "https://accounts.spotify.com/authorize?client_id=#{spotify_client_id}&response_type=code&redirect_uri=#{
        spotify_scope
      }&scope=#{spotify_scope}&state=fjosfnosfn"

    redirect(conn, external: spotify_oauth_url)
  end

  def index(conn, _) do
    current_user = conn.assigns[:current_user]
    current_user = Repo.preload(current_user, :spotify_credential)

    if current_user.spotify_credential do
      access_token = current_user.spotify_credential.access_token
      url = "https://api.spotify.com/v1/me"

      headers = [
        Authorization: "Bearer #{access_token}",
        Accept: "Application/json; Charset=utf-8"
      ]

      case HTTPoison.get(url, headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          spotify_info = Poison.decode!(body)
          render(conn, "index.html", spotify_info: spotify_info)

        {:ok, %HTTPoison.Response{status_code: 401}} ->
          refresh_url = "https://accounts.spotify.com/api/token"
          refresh_token = current_user.spotify_credential.refresh_token
          spotify_client_id = Application.fetch_env!(:music_manager, :spotify_client_id)
          spotify_secret_key = Application.fetch_env!(:music_manager, :spotify_secret_key)
          options = [hackney: [basic_auth: {spotify_client_id, spotify_secret_key}]]

          body =
            {:form,
             [
               {"grant_type", "refresh_token"},
               {"refresh_token", refresh_token}
             ]}

          case HTTPoison.post(refresh_url, body, [], options) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
              # save new access token
              %{"access_token" => access_token} = Poison.decode!(body)

              Integrations.update_spotify_credential(current_user.spotify_credential, %{
                access_token: access_token
              })

              url = "https://api.spotify.com/v1/me"

              headers = [
                Authorization: "Bearer #{access_token}",
                Accept: "Application/json; Charset=utf-8"
              ]

              case HTTPoison.get(url, headers) do
                {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                  spotify_info = Poison.decode!(body)
                  render(conn, "index.html", spotify_info: spotify_info)

                {:ok, %HTTPoison.Response{status_code: 401, body: body}} ->
                  %{error: %{status: _status_code, message: error_message}} = Poison.decode!(body)

                  conn
                  |> put_flash(:error, "Spotify credentials failed: #{error_message}")
                  |> redirect(to: Routes.spotify_session_path(conn, :new))
              end

            {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
              %{error: error, error_description: error_description} = Poison.decode!(body)

              conn
              |> put_flash(
                :error,
                "Spotify credentials refresh failed.
                Error: #{error}.
                Description: #{error_description}"
              )
              |> redirect(to: Routes.spotify_session_path(conn, :new))
          end
      end
    else
      conn
      |> put_flash(:error, "No Spotify credentials in account")
      |> redirect(to: Routes.spotify_session_path(conn, :new))
    end
  end

  def callback(conn, params) do
    spotify_client_id = Application.fetch_env!(:music_manager, :spotify_client_id)
    spotify_secret_key = Application.fetch_env!(:music_manager, :spotify_secret_key)

    case params do
      %{"code" => code, "state" => _state} ->
        case HTTPoison.post(
               "https://accounts.spotify.com/api/token",
               {:form,
                [
                  {"grant_type", "authorization_code"},
                  {"code", code},
                  {"redirect_uri", "http://localhost:4000/spotify_callback"},
                  {"client_id", spotify_client_id},
                  {"client_secret", spotify_secret_key}
                ]}
             ) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            IO.puts(body)

            %{"access_token" => access_token, "refresh_token" => refresh_token} =
              Poison.decode!(body)

            current_user = conn.assigns[:current_user]

            case Integrations.create_spotify_credential(current_user, %{
                   access_token: access_token,
                   refresh_token: refresh_token
                 }) do
              {:ok, _user} ->
                conn
                |> put_flash(:info, "Spotify login successful")
                |> redirect(to: Routes.spotify_session_path(conn, :index))

              {:error, _changeset} ->
                conn
                |> put_flash(:error, "Could not persist tokens")
                |> redirect(to: Routes.spotify_session_path(conn, :new))
            end

          {:error, %HTTPoison.Error{reason: reason}} ->
            conn
            |> put_flash(:error, "Spotify did not send tokens: #{reason}")
            |> redirect(to: Routes.spotify_session_path(conn, :new))
        end

      %{"error" => error, "state" => _state} ->
        conn
        |> put_flash(:error, "Authorization failed: #{error}")
        |> redirect(to: Routes.spotify_session_path(conn, :new))

      _ ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> redirect(to: Routes.spotify_session_path(conn, :new))
    end
  end
end
