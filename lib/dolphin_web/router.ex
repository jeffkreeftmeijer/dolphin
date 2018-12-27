defmodule DolphinWeb.Router do
  use DolphinWeb, :router

  pipeline :browser do
    unless Mix.env() == :test do
      plug BasicAuth, use_config: {:dolphin, :basic_auth}
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

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", DolphinWeb do
  #   pipe_through :api
  # end
end
