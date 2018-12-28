defmodule DolphinWeb.UpdateController do
  use DolphinWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"update" => update_params}) do
    {:ok, links} = Dolphin.Update.post(update_params)
    render(conn, "create.html", links: links)
  end
end
