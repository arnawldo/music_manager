defmodule MusicManagerWeb.PageController do
  use MusicManagerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
