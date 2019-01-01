defmodule Dolphin.Update.Twitter do
  defstruct content: nil, in_reply_to_id: nil, reply: nil, media: [], media_ids: []
  alias Dolphin.{Update, Update.Split, Update.Github}

  @twitter Application.get_env(:dolphin, :twitter, ExTwitter)
  @credentials Application.get_env(:dolphin, :twitter_credentials)
  @username @credentials[:username]

  def from_update(%Update{} = update) do
    from_update(update, %Dolphin.Update.Twitter{})
  end

  defp from_update(%Update{in_reply_to: "/" <> path} = update, acc) do
    case Github.get_metadata(path, "twitter") do
      {:ok, urls} ->
        from_update(%{update | in_reply_to: List.last(urls)}, acc)

      {:error, _} ->
        {:error, :invalid_in_reply_to}
    end
  end

  defp from_update(%Update{in_reply_to: url} = update, acc) when is_binary(url) and url != "" do
    case Regex.run(~r/https:\/\/twitter.com\/\w+\/status\/(\d+)/, url) do
      [_, in_reply_to_id] ->
        from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})

      _ ->
        {:error, :invalid_in_reply_to}
    end
  end

  defp from_update(%Update{text: text, media: media}, acc) do
    case validate_mentions(text) do
      :ok ->
        update =
          text
          |> replace_mentions()
          |> Update.replace_markdown_links()
          |> Split.split(280)
          |> from_splits(media, acc)

        {:ok, update}

      {:error, _} = error ->
        error
    end
  end

  defp from_splits(splits, media, update \\ %Dolphin.Update.Twitter{})

  defp from_splits([content | tail], media, update) do
    mentioned_images =
      ~r/!\[([^\]]*)]\(([^\)]+)\)/
      |> Regex.scan(content)
      |> Enum.map(fn [_match, alt, filename] ->
        upload =
          Enum.find(media, fn item ->
            "/media/" <> item.filename == filename
          end)

        {upload, alt}
      end)
      |> Enum.reject(fn {upload, _description} -> upload == nil end)

    %{
      update
      | content: remove_media_image_tags(content, mentioned_images),
        media: mentioned_images,
        reply: from_splits(tail, media)
    }
  end

  defp from_splits([], _media, _update), do: nil

  defp remove_media_image_tags(content, [{%{filename: filename}, alt} | tail]) do
    remove_media_image_tags(
      String.replace(content, ~r/\s*!\[#{alt}\]\(\/media\/#{filename}\)/, ""),
      tail
    )
  end

  defp remove_media_image_tags(content, []), do: content

  def post(%Dolphin.Update.Twitter{content: content, reply: reply, media: media} = update) do
    media_ids =
      Enum.map(media, fn {item, description} ->
        id = @twitter.upload_media(item.path, item.content_type)
        @twitter.set_media_alt(id, description)
        id
      end)

    %{id: id} = @twitter.update(content, post_options(%{update | media_ids: media_ids}))

    reply_urls =
      case reply do
        %Dolphin.Update.Twitter{} ->
          {:ok, urls} = post(%{reply | in_reply_to_id: id})
          urls

        _ ->
          []
      end

    {:ok, ["https://twitter.com/#{@username}/status/#{id}"] ++ reply_urls}
  end

  def post(%Update{} = update) do
    case from_update(update) do
      {:ok, update} -> post(update)
      {:error, _} = error -> error
    end
  end

  defp post_options(update) do
    post_options(update, [])
  end

  defp post_options(%Dolphin.Update.Twitter{in_reply_to_id: in_reply_to_id} = update, options)
       when in_reply_to_id != nil do
    post_options(
      Map.drop(update, [:in_reply_to_id]),
      Keyword.put(options, :in_reply_to_status_id, in_reply_to_id)
    )
  end

  defp post_options(%Dolphin.Update.Twitter{media_ids: media_ids} = update, options)
       when media_ids != [] do
    post_options(
      Map.drop(update, [:media_ids]),
      Keyword.put(options, :media_ids, media_ids)
    )
  end

  defp post_options(_, options), do: options

  defp replace_mentions(text) do
    Regex.replace(~r/@(\w+)@twitter.com/, text, "@\\1")
  end

  defp validate_mentions(text) do
    if Regex.match?(~r/(\@\w+(?!@twitter.com)\@[\w\.]+\.\w+)/, text) do
      {:error, :invalid_mention}
    else
      :ok
    end
  end
end
