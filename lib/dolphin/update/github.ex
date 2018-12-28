defmodule Dolphin.Update.Github do
  defstruct [:content, :filename]
  alias Dolphin.Update

  @github Application.get_env(:dolphin, :github, Tentacat)
  @credentials Application.get_env(:dolphin, :github_credentials)
  @username @credentials[:username]
  @repository @credentials[:repository]
  @client Module.concat(@github, Client).new(%{access_token: @credentials[:access_token]})

  def from_update(%Update{text: text} = update) do
    metadata = Update.metadata(update)

    %Dolphin.Update.Github{
      filename: Update.filename(update),
      content: FrontMatter.encode!(text, metadata)
    }
  end

  def post(%Update{text: text} = update) do
    metadata = Update.metadata(update)
    filename = Update.filename(update)
    content = text
              |> FrontMatter.encode!(metadata)
              |> Base.encode64()

    body = %{"content" => content, message: "Add " <> filename}
    Module.concat(@github, Contents).create(@client, @username, @repository, filename, body)
  end
end
