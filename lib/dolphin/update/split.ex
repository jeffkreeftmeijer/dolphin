defmodule Dolphin.Update.Split do
  def split(text, max) do
    splits =
      text
      |> String.split(~r/(\r?\n){3}/)
      |> Enum.flat_map(fn break ->
        break
        |> String.split(~r/(\r?\n){2}/)
        |> join!(max, [])
        |> Enum.reverse()
      end)

    splits
  end

  defp join!([head | tail], max, [previous | rest] = acc) do
    joined = previous <> "\n\n" <> head

    if String.length(joined) <= max do
      join!(tail, max, [joined | rest])
    else
      join!(tail, max, [head | acc])
    end
  end

  defp join!([head | tail], max, acc) do
    join!(tail, max, [head | acc])
  end

  defp join!([], _max, acc), do: acc
end
