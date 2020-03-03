defmodule MusicManager.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias MusicManager.Spotify.Credential

  schema "users" do
    field :password, :string
    field :username, :string

    has_one :spotify_credential, Credential, on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> unique_constraint(:username)
  end
end
