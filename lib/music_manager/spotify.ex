defmodule MusicManager.Spotify do
  @moduledoc """
  The Spotify context.
  Find functions for managing Spoitfy resources here.

  TODO: Separate web and DB interfaces
  """

  alias MusicManager.Accounts.User
  alias MusicManager.Repo
  alias MusicManager.Spotify

  @my_spotify_profile_url "https://api.spotify.com/v1/me"
  @spotify_refresh_token_url "https://accounts.spotify.com/api/token"
  @spotify_login_url "https://accounts.spotify.com/api/token"

  @doc """
  Creates a spotify credential for a user.

  ## Examples

      iex> create_spotify_credential(user, %{access_token: "access", refresh_token: "refresh"})
      {:ok, %Spotify.Credential{}}

      iex> create_spotify_credential(%{access_token: nil})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_spotify_credential(%User{}, map()) ::
          {:ok, %Spotify.Credential{}} | {:error, %Ecto.Changeset{}}
  def create_spotify_credential(%User{} = user, attrs \\ %{}) do
    %Spotify.Credential{}
    |> Spotify.Credential.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Generate Spotify oauth url used to redirect user during auth process

  ## Examples

     iex> generate_oauth_url()
     "https://accounts.spotify.com/authorize?client_id=CLIENT_ID&response_type=code&redirect_uri=REDIRECT_URI&scope=SCOPE&state=RANDOM_STATE"

  """
  @spec generate_oauth_url() :: String.t()
  def generate_oauth_url() do
    state = Ecto.UUID.generate()
    spotify_oauth_url() <> "&state=" <> state
  end

  @doc """
  Get my account details from Spotify
  """
  @spec get_my_spotify_details(%User{}) :: {:ok, map()} | {:error, atom() | String.t()}
  def get_my_spotify_details(%User{} = user) do
    user = Repo.preload(user, :spotify_credential)

    if user.spotify_credential do
      url = my_spotify_profile_url()
      access_token = user.spotify_credential.access_token

      headers = [
        Authorization: "Bearer #{access_token}",
        Accept: "Application/json; Charset=utf-8"
      ]

      case HTTPoison.get(url, headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, Poison.decode!(body)}

        {:ok, %HTTPoison.Response{status_code: 401}} ->
          {:error, :unauthorized}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, reason}

        _ ->
          {:error, :unknown}
      end
    else
      {:error, :nospotifycredential}
    end
  end

  @doc """
  Refresh Spotify access token
  """
  @spec get_new_access_token(%User{}) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def get_new_access_token(user) do
    user = Repo.preload(user, :spotify_credential)

    with %Spotify.Credential{refresh_token: refresh_token} <- user.spotify_credential,
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           request_new_access_token(refresh_token),
         %{"access_token" => access_token} <- Poison.decode!(body),
         {:ok, _updated_spotify_credential} <-
           update_spotify_credential(user.spotify_credential, %{access_token: access_token}) do
      {:ok, access_token}
    else
      nil ->
        {:error, :nospotifycredential}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        %{"error" => error, "error_description" => error_description} = Poison.decode!(body)
        {:error, error <> " : " <> error_description}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:error, %Ecto.Changeset{}} ->
        {:error, "Failed to save new access token"}

      _ ->
        {:error, :unknown}
    end
  end

  @doc """
  Login to Spotify. User authorization code to get access and refresh tokens
  """
  @spec login_to_spotify(String.t()) :: {:ok, map()} | {:error, atom() | String.t()}
  def login_to_spotify(auth_code) do
    url = spotify_login_url()

    body =
      {:form,
       [
         {"grant_type", "authorization_code"},
         {"code", auth_code},
         {"redirect_uri", "http://localhost:4000/spotify_callback"},
         {"client_id", spotify_client_id()},
         {"client_secret", spotify_secret_key()}
       ]}

    case HTTPoison.post(url, body) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"access_token" => access_token, "refresh_token" => refresh_token} = Poison.decode!(body)
        {:ok, %{access_token: access_token, refresh_token: refresh_token}}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        %{"error" => error, "error_description" => error_description} = Poison.decode!(body)
        {:error, error <> " : " <> error_description}

      _ ->
        {:error, :unknown}
    end
  end

  @doc """
  Updates a Spotify credential.

  ## Examples

      iex> update_spotify_credential(spotify_credential, %{field: new_value})
      {:ok, %Spotify.Credential{}}

      iex> update_spotify_credential(spotify_credential, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_spotify_credential(%Spotify.Credential{} = spotify_credential, attrs) do
    spotify_credential
    |> Spotify.Credential.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Return application's Spotify client id
  """
  def spotify_client_id, do: Application.fetch_env!(:music_manager, :spotify_client_id)

  @doc """
  Return application's Spotify secret key
  """
  def spotify_secret_key, do: Application.fetch_env!(:music_manager, :spotify_secret_key)

  @doc """
  Return Spotify read-write scope of application
  """
  def spotify_scope, do: Application.fetch_env!(:music_manager, :spotify_scope)

  @doc """
  Return application Spotify redirect uri
  """
  def spotify_redirect_uri, do: Application.fetch_env!(:music_manager, :spotify_redirect_uri)

  @doc """
  Return url for requesting access to user's Spotify data via OAuth
  """
  def spotify_oauth_url do
    "https://accounts.spotify.com/authorize" <>
      "?client_id=#{spotify_client_id()}" <>
      "&response_type=code" <>
      "&redirect_uri=#{spotify_redirect_uri()}" <>
      "&scope=#{spotify_scope()}"
  end

  @doc """
  Return url for logged in Spoitfy user profile
  """
  def my_spotify_profile_url, do: @my_spotify_profile_url

  @doc """
  Return url for refreshing Spotify access token
  """
  def spotify_refresh_token_url, do: @spotify_refresh_token_url

  @doc """
  Return url for logging in to Spotify
  """
  def spotify_login_url, do: @spotify_login_url

  @doc false
  defp request_new_access_token(refresh_token) do
    refresh_url = spotify_refresh_token_url()
    options = [hackney: [basic_auth: {spotify_client_id(), spotify_secret_key()}]]
    body = {:form, [{"grant_type", "refresh_token"}, {"refresh_token", refresh_token}]}

    HTTPoison.post(refresh_url, body, [], options)
  end
end
