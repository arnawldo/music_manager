defmodule MusicManager.Spotify.Credential do
  use Ecto.Schema
  import Ecto.Changeset
  alias MusicManager.Accounts.User

  schema "spotify_credentials" do
    field :access_token, :string
    field :refresh_token, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(spotify_credential, attrs) do
    spotify_credential
    |> cast(attrs, [:access_token, :refresh_token])
    |> validate_required([:access_token, :refresh_token])
  end
end
