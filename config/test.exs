use Mix.Config

# Configure your database
config :music_manager, MusicManager.Repo,
  username: "postgres",
  password: "postgres",
  database: "music_manager_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :music_manager, MusicManagerWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# set spotify values

# necessary scope for reading user and playlist data off spotify
config :music_manager, :spotify_scope, "user-read-private user-read-email playlist-read-private"
config :music_manager, :spotify_client_id, "some_client_id"
config :music_manager, :spotify_secret_key, "some_spotify_secret_key"
config :music_manager, :spotify_redirect_uri, "http://localhost:4002/spotify_redirect_uri"
