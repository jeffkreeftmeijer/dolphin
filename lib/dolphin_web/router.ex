defmodule DolphinWeb.Router do
  use DolphinWeb, :router

  pipeline :browser do
    case {Mix.env(), Application.get_env(:dolphin, :basic_auth)} do
      {:test, _} ->
        :ok

      {_, [{:username, username}, {:password, password}]}
      when is_binary(username) and is_binary(password) ->
        plug BasicAuth, use_config: {:dolphin, :basic_auth}

      _ ->
        :ok
    end

    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DolphinWeb do
    pipe_through :browser

    get "/", UpdateController, :new
    post "/", UpdateController, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", DolphinWeb do
  #   pipe_through :api
  # end
end
