defmodule Dolphin.Update.Mastodon do
  defstruct content: nil, in_reply_to_id: nil, reply: nil, media: [], media_ids: []
  alias Dolphin.{Update, Update.Split, Update.Github}

  @mastodon Application.get_env(:dolphin, :mastodon, Hunter)
  @credentials Application.get_env(:dolphin, :mastodon_credentials)
  @base_url @credentials[:base_url]
  @conn Hunter.new(@credentials)

  def from_update(%Update{} = update) do
    from_update(update, %Dolphin.Update.Mastodon{})
  end

  defp from_update(
         %Update{in_reply_to: "#{@base_url}/web/statuses/" <> in_reply_to_id} = update,
         acc
       ) do
    from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})
  end

  defp from_update(%Update{in_reply_to: "/" <> path} = update, acc) do
    case Github.get_metadata(path, "mastodon") do
      {:ok, urls} ->
        from_update(%{update | in_reply_to: List.last(urls)}, acc)

      {:error, _} ->
        {:error, :invalid_in_reply_to}
    end
  end

  defp from_update(%Update{in_reply_to: url} = update, acc) when is_binary(url) and url != "" do
    case @mastodon.search(@conn, url) do
      %{statuses: [%{id: in_reply_to_id} | _]} ->
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
          |> Update.replace_markdown_links()
          |> Split.split(500)
          |> from_splits(media, acc)

        {:ok, update}

      {:error, _} = error ->
        error
    end
  end

  defp from_splits(splits, media, update \\ %Dolphin.Update.Mastodon{})

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

  def post(%Dolphin.Update.Mastodon{content: content, reply: reply, media: media} = update) do
    media_ids =
      Enum.map(media, fn {item, description} ->
        %Hunter.Attachment{id: id} =
          @mastodon.upload_media(@conn, item.path, description: description)

        id
      end)

    %{id: id, url: url} =
      @mastodon.create_status(@conn, content, post_options(%{update | media_ids: media_ids}))

    reply_urls =
      case reply do
        %Dolphin.Update.Mastodon{} ->
          {:ok, urls} = post(%{reply | in_reply_to_id: id})
          urls

        _ ->
          []
      end

    {:ok, [url] ++ reply_urls}
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

  defp post_options(%Dolphin.Update.Mastodon{in_reply_to_id: in_reply_to_id} = update, options)
       when in_reply_to_id != nil do
    post_options(
      Map.drop(update, [:in_reply_to_id]),
      Keyword.put(options, :in_reply_to_id, in_reply_to_id)
    )
  end

  defp post_options(%Dolphin.Update.Mastodon{media_ids: media_ids} = update, options)
       when media_ids != [] do
    post_options(
      Map.drop(update, [:media_ids]),
      Keyword.put(options, :media_ids, media_ids)
    )
  end

  defp post_options(_, options), do: options

  defp validate_mentions(text) do
    if(Regex.match?(~r/\@.+@twitter.com/, text)) do
      {:error, :invalid_mention}
    else
      :ok
    end
  end
end
