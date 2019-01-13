defmodule Dolphin.Update.Split do
  def split(text, max) do
    {mentions, content} =
      case Regex.run(~r/^(\@[\w_]+\s)*/, text) do
        [match, _] ->
          {match, String.replace_leading(text, match, "")}

        _ ->
          {"", text}
      end

    splits =
      content
      |> String.split(~r/(\r?\n){3}/)
      |> Enum.flat_map(fn break ->
        break
        |> String.split(~r/(\r?\n){2}/)
        |> join!(max, [], mentions)
        |> Enum.reverse()
      end)

    splits
  end

  defp join!([head | tail], max, [previous | rest] = acc, prefix) do
    joined = previous <> "\n\n" <> head

    if joined
       |> shorten_urls
       |> remove_local_images
       |> String.length() <= max do
      join!(tail, max, [joined | rest], prefix)
    else
      join!(tail, max, [prefix <> head | acc], prefix)
    end
  end

  defp join!([head | tail], max, acc, prefix) do
    join!(tail, max, [prefix <> head | acc], prefix)
  end

  defp join!([], _max, acc, _prefix), do: acc

  defp shorten_urls(text) do
    Regex.replace(~r/https?:\/\/[\w\.\/-]+/, text, &String.slice(&1, 0..22))
  end

  defp remove_local_images(text) do
    Regex.replace(~r/!\[[^\]]*]\(\/[^\)]+\)\s*/, text, "")
  end
end
