defmodule MusicManagerWeb.UserController do
  use MusicManagerWeb, :controller
  alias MusicManager.Accounts

  def new(conn, _params) do
    changeset = Accounts.change_user(%Accounts.User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"register_details" => register_details} = _params) do
    case Accounts.register_user(register_details) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Registration successful")
        |> redirect(to: Routes.session_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Registration unsuccessful")
        |> render("new.html", changeset: changeset)
    end
  end
end
