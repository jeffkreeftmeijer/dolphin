defmodule DolphinWeb.UpdateController do
  use DolphinWeb, :controller
  alias Dolphin.Update

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"update" => update_params}) do
    {:ok, links} =
      update_params
      |> Update.from_params()
      |> Update.post()

    render(conn, "create.html", links: links)
  end
end
