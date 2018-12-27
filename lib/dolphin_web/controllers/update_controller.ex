defmodule DolphinWeb.UpdateController do
  use DolphinWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"update" => update_params}) do
    render(conn, "create.html")
  end
end
