defmodule MusicManager.Integrations do
  @moduledoc """
  The Integrations context.
  """

  import Ecto.Query, warn: false
  alias MusicManager.Repo

  alias MusicManager.Integrations.SpotifyCredential
  alias MusicManager.Accounts
  alias MusicManager.Accounts.User

  @doc """
  Returns the list of spotify_credentials.

  ## Examples

      iex> list_spotify_credentials()
      [%SpotifyCredential{}, ...]

  """
  def list_spotify_credentials do
    Repo.all(SpotifyCredential)
  end

  @doc """
  Gets a single spotify_credential.

  Raises `Ecto.NoResultsError` if the Spotify credential does not exist.

  ## Examples

      iex> get_spotify_credential!(123)
      %SpotifyCredential{}

      iex> get_spotify_credential!(456)
      ** (Ecto.NoResultsError)

  """
  def get_spotify_credential!(id), do: Repo.get!(SpotifyCredential, id)

  @doc """
  Creates a spotify_credential.

  ## Examples

      iex> create_spotify_credential(%{field: value})
      {:ok, %SpotifyCredential{}}

      iex> create_spotify_credential(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_spotify_credential(%User{} = user, attrs \\ %{}) do
    user
    |> Repo.preload(:spotify_credential)
    |> Accounts.change_user()
    |> Ecto.Changeset.put_assoc(:spotify_credential, attrs)
    |> Repo.update()
  end

  @doc """
  Updates a spotify_credential.

  ## Examples

      iex> update_spotify_credential(spotify_credential, %{field: new_value})
      {:ok, %SpotifyCredential{}}

      iex> update_spotify_credential(spotify_credential, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_spotify_credential(%SpotifyCredential{} = spotify_credential, attrs) do
    spotify_credential
    |> SpotifyCredential.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a spotify_credential.

  ## Examples

      iex> delete_spotify_credential(spotify_credential)
      {:ok, %SpotifyCredential{}}

      iex> delete_spotify_credential(spotify_credential)
      {:error, %Ecto.Changeset{}}

  """
  def delete_spotify_credential(%SpotifyCredential{} = spotify_credential) do
    Repo.delete(spotify_credential)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking spotify_credential changes.

  ## Examples

      iex> change_spotify_credential(spotify_credential)
      %Ecto.Changeset{source: %SpotifyCredential{}}

  """
  def change_spotify_credential(%SpotifyCredential{} = spotify_credential) do
    SpotifyCredential.changeset(spotify_credential, %{})
  end
end
