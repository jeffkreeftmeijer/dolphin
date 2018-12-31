defmodule DolphinWeb.UpdateController do
  use DolphinWeb, :controller
  alias Dolphin.Update

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"preview" => _, "update" => update_params}) do
    update = Dolphin.Update.from_params(update_params)

    github = Dolphin.Update.Github.from_update(update)

    twitter =
      case Dolphin.Update.Twitter.from_update(update) do
        {:ok, update} -> update
        _ -> nil
      end

    mastodon =
      case Dolphin.Update.Mastodon.from_update(update) do
        {:ok, update} -> update
        _ -> nil
      end

    render(conn, "preview.html", github: github, twitter: twitter, mastodon: mastodon)
  end

  def create(conn, %{"update" => update_params}) do
    {:ok, links} =
      update_params
      |> Update.from_params()
      |> Update.post()

    render(conn, "create.html", links: links)
  end
end
