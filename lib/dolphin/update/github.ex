defmodule Dolphin.Update.Github do
  defstruct content: nil, filename: nil, media: []
  alias Dolphin.Update

  @github Application.get_env(:dolphin, :github, Tentacat)
  @credentials Application.get_env(:dolphin, :github_credentials)
  @username @credentials[:username]
  @repository @credentials[:repository]
  @client Module.concat(@github, Client).new(%{access_token: @credentials[:access_token]})

  def from_update(%Update{text: text} = update) do
    metadata = Update.metadata(update)

    content =
      text
      |> String.replace("\r", "")
      |> FrontMatter.encode!(metadata)

    %Dolphin.Update.Github{
      filename: Update.filename(update),
      content: content,
      media: update.media
    }
  end

  def post(%Dolphin.Update.Github{filename: filename, content: content, media: media}) do
    Enum.each(media, &do_post("media/" <> &1.filename, File.read!(&1.path)))
    do_post(filename, content)
  end

  def post(%Update{} = update) do
    update
    |> from_update
    |> post
  end

  defp do_post(filename, content) do
    body = %{"content" => Base.encode64(content), message: "Add " <> filename, branch: "main"}

    {201, %{"content" => %{"_links" => %{"html" => link}}}, _response} =
      Module.concat(@github, Contents).create(@client, @username, @repository, filename, body)

    {:ok, [link]}
  end

  def get_metadata(path, key) do
    filename =
      path
      |> String.replace("/", "-")
      |> String.replace_trailing(".html", ".md")

    {200, %{"content" => content}, _} =
      Module.concat(@github, Contents).find(@client, @username, @repository, filename)

    case content
         |> Base.decode64!(ignore: :whitespace)
         |> FrontMatter.decode() do
      {:ok, %{^key => value}, _} ->
        {:ok, value}

      _ ->
        {:error, :key_not_found}
    end
  end
end
