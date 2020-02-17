defmodule MusicManagerWeb.SessionController do
  use MusicManagerWeb, :controller
  alias MusicManager.Accounts
  alias MusicManagerWeb.Plugs.Auth

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"login_details" => %{"username" => username, "password" => password}}) do
    case Accounts.authenticate_by_username_password(username, password) do
      {:ok, user} ->
        conn
        |> Auth.login(user)
        |> put_flash(:info, "Succesfully logged in")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Login failed")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Auth.logout()
    |> put_flash(:info, "You've been logged out")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
