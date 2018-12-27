defmodule DolphinWeb.PageController do
  use DolphinWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
