defmodule Dolphin.Update.Mastodon do
  defstruct [:content, :in_reply_to_id, :reply]
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

  defp from_update(%Update{text: text}, acc) do
    case validate_mentions(text) do
      :ok ->
        update =
          text
          |> Update.replace_markdown_links()
          |> Split.split(500)
          |> from_splits(acc)

        {:ok, update}

      {:error, _} = error ->
        error
    end
  end

  defp from_splits(splits, update \\ %Dolphin.Update.Mastodon{})

  defp from_splits([content | tail], update) do
    %{update | content: content, reply: from_splits(tail)}
  end

  defp from_splits([], _update), do: nil

  def post(%Dolphin.Update.Mastodon{reply: reply} = update) do
    %{id: id, url: url} = do_post(update)

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

  defp do_post(%Dolphin.Update.Mastodon{content: content, in_reply_to_id: in_reply_to_id})
       when in_reply_to_id != nil do
    @mastodon.create_status(@conn, content, in_reply_to_id: in_reply_to_id)
  end

  defp do_post(%Dolphin.Update.Mastodon{content: content}) do
    @mastodon.create_status(@conn, content)
  end

  defp validate_mentions(text) do
    if(Regex.match?(~r/\@.+@twitter.com/, text)) do
      {:error, :invalid_mention}
    else
      :ok
    end
  end
end
