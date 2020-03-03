defmodule MusicManagerWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias MusicManagerWeb.Router.Helpers, as: Routes
  alias MusicManager.Accounts.User
  alias MusicManager.Accounts
  alias MusicManager.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    cond do
      conn.assigns[:current_user] ->
        conn

      user = user_id && Accounts.get_user!(user_id) ->
        user = Repo.preload(user, :spotify_credential)
        assign(conn, :current_user, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end

  def login(conn, %User{} = user) do
    conn
    |> put_session(:user_id, user.id)
    |> assign(:current_user, user)
  end

  def logout(conn) do
    conn
    |> clear_session()
    |> assign(:current_user, nil)
  end
end
