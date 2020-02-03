defmodule MusicManager.Repo do
  use Ecto.Repo,
    otp_app: :music_manager,
    adapter: Ecto.Adapters.Postgres
end
