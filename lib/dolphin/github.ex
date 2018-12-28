defmodule Dolphin.Github do
  alias Dolphin.Update

  @github Application.get_env(:dolphin, :github, Tentacat)
  @credentials Application.get_env(:dolphin, :github_credentials)
  @username @credentials[:username]
  @repository @credentials[:repository]
  @client Module.concat(@github, Client).new(%{access_token: @credentials[:access_token]})

  def post(%Update{text: text} = update) do
    filename = Update.filename(update)
    body = %{"content" => Base.encode64(text), message: "Add " <> filename}

    Module.concat(@github, Contents).create(@client, @username, @repository, filename, body)
  end
end
