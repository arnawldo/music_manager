defmodule MusicManagerWeb.SpotifySessionController do
  use MusicManagerWeb, :controller
  alias MusicManager.Spotify
  import MusicManagerWeb.Plugs.Auth, only: [authenticate_user: 2]

  plug :authenticate_user

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, _) do
    random_string = Ecto.UUID.generate()
    spotify_oauth_url = Spotify.spotify_oauth_url() <> "&state=#{random_string}"

    conn
    |> put_session(:spotify_oauth_state, random_string)
    |> redirect(external: spotify_oauth_url)
  end

  def show(conn, _) do
    current_user = conn.assigns[:current_user]

    case Spotify.get_my_spotify_details(current_user) do
      {:ok, spotify_info} ->
        render(conn, "show.html", spotify_info: spotify_info)

      {:error, :unauthorized} ->
        conn
        |> put_flash(:info, "Refreshing spotify session")
        |> redirect(to: Routes.spotify_session_path(conn, :refresh))

      {:error, :nospotifycredential} ->
        conn
        |> put_flash(:error, "Need to login to Spotify first")
        |> redirect(to: Routes.spotify_session_path(conn, :new))

      _ ->
        conn
        |> put_flash(:error, "Server error")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def refresh(conn, _params) do
    current_user = conn.assigns[:current_user]

    case Spotify.get_new_access_token(current_user) do
      {:ok, _access_token} ->
        redirect(conn, to: Routes.page_path(conn, :index))

      {:error, :nospotifycredential} ->
        conn
        |> put_flash(:error, "Need to login to Spotify first")
        |> redirect(to: Routes.spotify_session_path(conn, :new))

      _ ->
        conn
        |> put_flash(:error, "Server error")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def callback(conn, params) do
    case params do
      %{"code" => code, "state" => _state} ->
        # TODO validate state
        case Spotify.login_to_spotify(code) do
          {:ok, spotify_credential_attrs} ->
            current_user = conn.assigns[:current_user]

            case Spotify.create_spotify_credential(current_user, spotify_credential_attrs) do
              {:ok, _created_spotify_credential} ->
                conn
                |> put_flash(:info, "Spotify OAuth successful")
                |> redirect(to: Routes.spotify_session_path(conn, :show))

              _ ->
                conn
                |> put_flash(
                  :error,
                  "Spotify authentication failed: Could not save Spotify credentials"
                )
                |> redirect(to: Routes.page_path(conn, :index))
            end

          _ ->
            conn
            |> put_flash(:error, "Spotify authentication failed: Could not get auth code")
            |> redirect(to: Routes.page_path(conn, :index))
        end

      _ ->
        conn
        |> put_flash(:error, "Spotify authentication failed: No Spotify auth code returned")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
