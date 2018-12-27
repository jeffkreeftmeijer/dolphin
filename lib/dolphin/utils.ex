defmodule Dolphin.Utils do
  @doc ~S"""
  Returns a string consisting only of characters in the allowed character list.

  ## Examples

      iex> Dolphin.Utils.filter_characters("$ man ed", ['e', 'd'])
      "ed"

  """
  def filter_characters(string, allowed) when is_binary(string) do
    string
    |> String.to_charlist()
    |> filter_characters(allowed, [])
    |> Enum.reverse
    |> List.to_string()
  end

  defp filter_characters([character | tail], allowed, acc) do
    if Enum.any?(allowed, &(character in &1)) do
      filter_characters(tail, allowed, [character | acc])
    else
      filter_characters(tail, allowed, acc)
    end
  end

  defp filter_characters([], _allowed, acc), do: acc
end
