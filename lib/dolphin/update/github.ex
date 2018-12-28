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

  def post(%Dolphin.Update.Github{filename: filename, content: content}) do
    body = %{"content" => Base.encode64(content), message: "Add " <> filename}

    {201, %{"content" => %{"_links" => %{"html" => link}}}, _response} =
      Module.concat(@github, Contents).create(@client, @username, @repository, filename, body)

    {:ok, [link]}
  end

  def post(%Update{} = update) do
    update
    |> from_update
    |> post
  end
end
