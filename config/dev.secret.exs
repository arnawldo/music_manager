# Dev secrets
use Mix.Config

# spotify variables
spotify_client_id =
  System.get_env("SPOTIFY_CLIENT_ID") ||
    raise """
    environment variable SPOTIFY_CLIENT_ID is missing.
    Check spotify app dashboard settings for value.
    """

spotify_secret_key =
  System.get_env("SPOTIFY_SECRET_KEY") ||
    raise """
    environment variable SPOTIFY_SECRET_KEY is missing.
    Check spotify app dashboard settings for value.
    """

config :music_manager, :spotify_client_id, spotify_client_id
config :music_manager, :spotify_secret_key, spotify_secret_key

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :music_manager, MusicManagerWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
