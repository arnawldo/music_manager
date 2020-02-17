defmodule MusicManagerWeb.SpotifyCredentialController do
  use MusicManagerWeb, :controller

  alias MusicManager.Integrations
  alias MusicManager.Integrations.SpotifyCredential

  def index(conn, _params) do
    spotify_credentials = Integrations.list_spotify_credentials()
    render(conn, "index.html", spotify_credentials: spotify_credentials)
  end

  def new(conn, _params) do
    changeset = Integrations.change_spotify_credential(%SpotifyCredential{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"spotify_credential" => spotify_credential_params}) do
    case Integrations.create_spotify_credential(spotify_credential_params) do
      {:ok, spotify_credential} ->
        conn
        |> put_flash(:info, "Spotify credential created successfully.")
        |> redirect(to: Routes.spotify_credential_path(conn, :show, spotify_credential))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    spotify_credential = Integrations.get_spotify_credential!(id)
    render(conn, "show.html", spotify_credential: spotify_credential)
  end

  def edit(conn, %{"id" => id}) do
    spotify_credential = Integrations.get_spotify_credential!(id)
    changeset = Integrations.change_spotify_credential(spotify_credential)
    render(conn, "edit.html", spotify_credential: spotify_credential, changeset: changeset)
  end

  def update(conn, %{"id" => id, "spotify_credential" => spotify_credential_params}) do
    spotify_credential = Integrations.get_spotify_credential!(id)

    case Integrations.update_spotify_credential(spotify_credential, spotify_credential_params) do
      {:ok, spotify_credential} ->
        conn
        |> put_flash(:info, "Spotify credential updated successfully.")
        |> redirect(to: Routes.spotify_credential_path(conn, :show, spotify_credential))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", spotify_credential: spotify_credential, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    spotify_credential = Integrations.get_spotify_credential!(id)
    {:ok, _spotify_credential} = Integrations.delete_spotify_credential(spotify_credential)

    conn
    |> put_flash(:info, "Spotify credential deleted successfully.")
    |> redirect(to: Routes.spotify_credential_path(conn, :index))
  end
end
