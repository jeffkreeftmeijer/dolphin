defmodule Dolphin.Github do
  alias Dolphin.Update

  @github Application.get_env(:dolphin, :github, Tentacat)
  @credentials Application.get_env(:dolphin, :github_credentials)
  @username @credentials[:username]
  @repository @credentials[:repository]
  @client Module.concat(@github, Client).new(%{access_token: @credentials[:access_token]})

  def post(%Update{in_reply_to: nil, text: text} = update) do
    do_post(text, Update.filename(update))
  end

  def post(%Update{in_reply_to: in_reply_to, text: text} = update) do
    text
    |> FrontMatter.encode!(%{in_reply_to: in_reply_to})
    |> do_post(Update.filename(update))
  end

  defp do_post(content, filename) do
    body = %{"content" => Base.encode64(content), message: "Add " <> filename}

    Module.concat(@github, Contents).create(@client, @username, @repository, filename, body)
  end
end
