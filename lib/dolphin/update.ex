defmodule Dolphin.Update do
  defstruct text: ""

  @date Application.get_env(:dolphin, :date, Date)

  @doc ~S"""
  Generates a file name based on today's date and the update's text.

  ## Examples

      iex> Dolphin.Update.filename(%Dolphin.Update{text: "$ man ed\n\n#currentstatus"})
      "2018-12-27-man-ed-currentstatus.md"

  """
  def filename(%Dolphin.Update{text: text}) do
    (@date.to_iso8601(@date.utc_today) <> "-" <> text)
    |> Dolphin.Utils.filter_characters([' ', '\n', '-', ?a..?z, ?A..?Z, ?0..?9])
    |> String.split(~r/\W+/, trim: true)
    |> Enum.take(8)
    |> Enum.join("-")
    |> Kernel.<>(".md")
  end
end
