defmodule MusicManager.Repo.Migrations.CreateSpotifyCredentials do
  use Ecto.Migration

  def change do
    create table(:spotify_credentials) do
      add :access_token, :string
      add :refresh_token, :string

      timestamps()
    end
  end
end
