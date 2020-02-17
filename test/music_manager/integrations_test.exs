defmodule MusicManager.IntegrationsTest do
  use MusicManager.DataCase

  alias MusicManager.Integrations

  describe "spotify_credentials" do
    alias MusicManager.Integrations.SpotifyCredential

    @valid_attrs %{access_token: "some access_token", refresh_token: "some refresh_token"}
    @update_attrs %{
      access_token: "some updated access_token",
      refresh_token: "some updated refresh_token"
    }
    @invalid_attrs %{access_token: nil, refresh_token: nil}

    def spotify_credential_fixture(attrs \\ %{}) do
      {:ok, spotify_credential} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Integrations.create_spotify_credential()

      spotify_credential
    end

    test "list_spotify_credentials/0 returns all spotify_credentials" do
      spotify_credential = spotify_credential_fixture()
      assert Integrations.list_spotify_credentials() == [spotify_credential]
    end

    test "get_spotify_credential!/1 returns the spotify_credential with given id" do
      spotify_credential = spotify_credential_fixture()
      assert Integrations.get_spotify_credential!(spotify_credential.id) == spotify_credential
    end

    test "create_spotify_credential/1 with valid data creates a spotify_credential" do
      assert {:ok, %SpotifyCredential{} = spotify_credential} =
               Integrations.create_spotify_credential(@valid_attrs)

      assert spotify_credential.access_token == "some access_token"
      assert spotify_credential.refresh_token == "some refresh_token"
    end

    test "create_spotify_credential/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Integrations.create_spotify_credential(@invalid_attrs)
    end

    test "update_spotify_credential/2 with valid data updates the spotify_credential" do
      spotify_credential = spotify_credential_fixture()

      assert {:ok, %SpotifyCredential{} = spotify_credential} =
               Integrations.update_spotify_credential(spotify_credential, @update_attrs)

      assert spotify_credential.access_token == "some updated access_token"
      assert spotify_credential.refresh_token == "some updated refresh_token"
    end

    test "update_spotify_credential/2 with invalid data returns error changeset" do
      spotify_credential = spotify_credential_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Integrations.update_spotify_credential(spotify_credential, @invalid_attrs)

      assert spotify_credential == Integrations.get_spotify_credential!(spotify_credential.id)
    end

    test "delete_spotify_credential/1 deletes the spotify_credential" do
      spotify_credential = spotify_credential_fixture()

      assert {:ok, %SpotifyCredential{}} =
               Integrations.delete_spotify_credential(spotify_credential)

      assert_raise Ecto.NoResultsError, fn ->
        Integrations.get_spotify_credential!(spotify_credential.id)
      end
    end

    test "change_spotify_credential/1 returns a spotify_credential changeset" do
      spotify_credential = spotify_credential_fixture()
      assert %Ecto.Changeset{} = Integrations.change_spotify_credential(spotify_credential)
    end
  end
end
