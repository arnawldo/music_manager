defmodule MusicManager.Repo.Migrations.AddUserIdToSpotifyCredential do
  use Ecto.Migration

  def change do
    alter table(:spotify_credentials) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create index(:spotify_credentials, [:user_id])
  end
end
