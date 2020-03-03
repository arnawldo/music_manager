defmodule MusicManagerWeb.Router do
  use MusicManagerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MusicManagerWeb.Plugs.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MusicManagerWeb do
    pipe_through :browser

    get "/", PageController, :index

    resources "/user", UserController, only: [:new, :create]
    resources "/session", SessionController, only: [:new, :create, :delete], singleton: true

    get "/spotify_callback", SpotifySessionController, :callback
    get "/spotify_refresh", SpotifySessionController, :refresh

    resources "/spotify_sessions", SpotifySessionController,
      only: [:new, :create, :show],
      singleton: true
  end

  # Other scopes may use custom stacks.
  # scope "/api", MusicManagerWeb do
  #   pipe_through :api
  # end
end
