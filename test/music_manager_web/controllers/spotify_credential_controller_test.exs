defmodule MusicManagerWeb.SpotifyCredentialControllerTest do
  use MusicManagerWeb.ConnCase

  alias MusicManager.Integrations

  @create_attrs %{access_token: "some access_token", refresh_token: "some refresh_token"}
  @update_attrs %{
    access_token: "some updated access_token",
    refresh_token: "some updated refresh_token"
  }
  @invalid_attrs %{access_token: nil, refresh_token: nil}

  def fixture(:spotify_credential) do
    {:ok, spotify_credential} = Integrations.create_spotify_credential(@create_attrs)
    spotify_credential
  end

  describe "index" do
    test "lists all spotify_credentials", %{conn: conn} do
      conn = get(conn, Routes.spotify_credential_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Spotify credentials"
    end
  end

  describe "new spotify_credential" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.spotify_credential_path(conn, :new))
      assert html_response(conn, 200) =~ "New Spotify credential"
    end
  end

  describe "create spotify_credential" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn =
        post(conn, Routes.spotify_credential_path(conn, :create),
          spotify_credential: @create_attrs
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.spotify_credential_path(conn, :show, id)

      conn = get(conn, Routes.spotify_credential_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Spotify credential"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.spotify_credential_path(conn, :create),
          spotify_credential: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Spotify credential"
    end
  end

  describe "edit spotify_credential" do
    setup [:create_spotify_credential]

    test "renders form for editing chosen spotify_credential", %{
      conn: conn,
      spotify_credential: spotify_credential
    } do
      conn = get(conn, Routes.spotify_credential_path(conn, :edit, spotify_credential))
      assert html_response(conn, 200) =~ "Edit Spotify credential"
    end
  end

  describe "update spotify_credential" do
    setup [:create_spotify_credential]

    test "redirects when data is valid", %{conn: conn, spotify_credential: spotify_credential} do
      conn =
        put(conn, Routes.spotify_credential_path(conn, :update, spotify_credential),
          spotify_credential: @update_attrs
        )

      assert redirected_to(conn) ==
               Routes.spotify_credential_path(conn, :show, spotify_credential)

      conn = get(conn, Routes.spotify_credential_path(conn, :show, spotify_credential))
      assert html_response(conn, 200) =~ "some updated access_token"
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      spotify_credential: spotify_credential
    } do
      conn =
        put(conn, Routes.spotify_credential_path(conn, :update, spotify_credential),
          spotify_credential: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Spotify credential"
    end
  end

  describe "delete spotify_credential" do
    setup [:create_spotify_credential]

    test "deletes chosen spotify_credential", %{
      conn: conn,
      spotify_credential: spotify_credential
    } do
      conn = delete(conn, Routes.spotify_credential_path(conn, :delete, spotify_credential))
      assert redirected_to(conn) == Routes.spotify_credential_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.spotify_credential_path(conn, :show, spotify_credential))
      end
    end
  end

  defp create_spotify_credential(_) do
    spotify_credential = fixture(:spotify_credential)
    {:ok, spotify_credential: spotify_credential}
  end
end
