defmodule MusicManager.SpotifyTest do
  use MusicManager.DataCase, async: true
  alias MusicManager.Accounts
  alias MusicManager.Repo
  alias MusicManager.Spotify

  import Mock

  describe "Spotify authentication" do
    setup [:create_user]

    test "can store spotify credentials for a user", %{user: user} do
      user = Repo.preload(user, :spotify_credential)
      refute user.spotify_credential

      valid_spoitfy_credential_attrs = %{access_token: "access", refresh_token: "refresh"}

      {:ok, spotify_credential} =
        Spotify.create_spotify_credential(user, valid_spoitfy_credential_attrs)

      assert %Spotify.Credential{access_token: "access", refresh_token: "refresh"} =
               spotify_credential

      user = Accounts.get_user!(user.id)
      user = Repo.preload(user, :spotify_credential)
      assert %Spotify.Credential{} = user.spotify_credential
    end

    test "generate_oauth_url/0 returns correct Spotify oauth url" do
      oauth_url = Spotify.generate_oauth_url()

      url_params_to_env_map = %{
        "client_id" => :spotify_client_id,
        "redirect_uri" => :spotify_redirect_uri,
        "scope" => :spotify_scope
      }

      for param <- Map.keys(url_params_to_env_map) do
        {:ok, url_param_regex} = Regex.compile("[?&]#{param}=(?<captured_param>[^&]+)")

        %{"captured_param" => captured_param} = Regex.named_captures(url_param_regex, oauth_url)

        assert captured_param ==
                 Application.fetch_env!(:music_manager, url_params_to_env_map[param])
      end
    end
  end

  describe "Fetch Spotify account details for user with saved spotify credentials" do
    setup [:create_user, :create_spotify_credential_for_user]

    test "get_my_spotify_details/1 fetches my Spotify user account details", %{user: user} do
      get_mock = fn _url, _headers ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Poison.encode!(%{"username" => "test_user"})
         }}
      end

      with_mock HTTPoison, get: get_mock do
        assert {:ok, %{"username" => "test_user"}} = Spotify.get_my_spotify_details(user)
      end
    end

    test "get_my_spotify_details/1 returns error when access token is expired", %{user: user} do
      get_mock = fn _url, _headers ->
        {:ok,
         %HTTPoison.Response{
           status_code: 401,
           body: Poison.encode!(%{error: %{status: 401, message: "Invalid access token"}})
         }}
      end

      with_mock HTTPoison, get: get_mock do
        assert {:error, :unauthorized} = Spotify.get_my_spotify_details(user)
      end
    end

    test "get_my_spotify_details/1 returns error when connection issue", %{user: user} do
      get_mock = fn _url, _headers ->
        {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}}
      end

      with_mock HTTPoison, get: get_mock do
        assert {:error, :econnrefused} = Spotify.get_my_spotify_details(user)
      end
    end

    test "get_my_spotify_details/1 returns error when an unknown issue occurs", %{user: user} do
      get_mock = fn _url, _headers ->
        {:ok, %HTTPoison.Response{status_code: 502}}
      end

      with_mock HTTPoison, get: get_mock do
        assert {:error, :unknown} = Spotify.get_my_spotify_details(user)
      end
    end
  end

  describe "Fetch Spotify account details for user without saved spotify credentials" do
    setup [:create_user]

    test "get_my_spotify_details/1 returns error", %{user: user} do
      assert {:error, :nospotifycredential} = Spotify.get_my_spotify_details(user)
    end
  end

  describe "User with saved spotify credentials" do
    setup [:create_user, :create_spotify_credential_for_user]

    test "get_new_access_token/1 returns new access token when credentials are valid", %{
      user: user
    } do
      post_mock = fn _url, _body, _headers, _options ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Poison.encode!(%{access_token: "some_access_token"})
         }}
      end

      with_mock HTTPoison, post: post_mock do
        assert {:ok, "some_access_token"} = Spotify.get_new_access_token(user)
      end
    end

    test "get_new_access_token/1 returns error when credentials are invalid", %{
      user: user
    } do
      post_mock = fn _url, _body, _headers, _options ->
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body:
             Poison.encode!(%{
               "error" => "invalid_grant",
               "error_description" => "Invalid refresh token"
             })
         }}
      end

      with_mock HTTPoison, post: post_mock do
        assert {:error, "invalid_grant : Invalid refresh token"} =
                 Spotify.get_new_access_token(user)
      end
    end

    test "get_new_access_token/1 returns error when there are network/connection issues", %{
      user: user
    } do
      post_mock = fn _url, _body, _headers, _options ->
        {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}}
      end

      with_mock HTTPoison, post: post_mock do
        assert {:error, :econnrefused} = Spotify.get_new_access_token(user)
      end
    end

    test "get_new_access_token/1 returns error when new access token cannot be saved", %{
      user: user
    } do
      # Don't see this happening, but say Spotify returns access token that empty or too long
      post_mock = fn _url, _body, _headers, _options ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Poison.encode!(%{access_token: nil})
         }}
      end

      with_mock HTTPoison, post: post_mock do
        assert {:error, "Failed to save new access token"} = Spotify.get_new_access_token(user)
      end
    end
  end

  describe "User with no saved spotify credentials" do
    setup [:create_user]

    test "get_new_access_token/1 returns error", %{user: user} do
      assert {:error, :nospotifycredential} = Spotify.get_new_access_token(user)
    end
  end

  defp create_user(_context) do
    {:ok, user} = Accounts.create_user(%{username: "some_username", password: "some_password"})

    [user: user]
  end

  defp create_spotify_credential_for_user(context) do
    user = context[:user]

    {:ok, _} =
      Spotify.create_spotify_credential(user, %{
        access_token: "some_access_token",
        refresh_token: "some_refresh_token"
      })

    [user: user]
  end
end
