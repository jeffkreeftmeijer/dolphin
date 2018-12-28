defmodule Dolphin.Update do
  defstruct text: ""
  alias Dolphin.Github

  @date Application.get_env(:dolphin, :date, Date)

  def post(%Dolphin.Update{} = update) do
    {201, %{"content" => %{"_links" => %{"html" => link}}}, _} = Github.post(update)

    {:ok, [link]}
  end

  def post(%{"text" => text}), do: post(%Dolphin.Update{text: text})

  @doc ~S"""
  Generates a file name based on today's date and the update's text.

  ## Examples

      iex> Dolphin.Update.filename(%Dolphin.Update{text: "$ man ed\n\n#currentstatus"})
      "2018-12-27-man-ed-currentstatus.md"
      iex> Dolphin.Update.filename(%Dolphin.Update{text: "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!"})
      "2018-12-27-because-ed-is-the-standard.md"

  """
  def filename(%Dolphin.Update{text: text}) do
    (@date.to_iso8601(@date.utc_today) <> "-" <> text)
    |> Dolphin.Utils.filter_characters([' ', '\n', '-', '@', ?a..?z, ?A..?Z, ?0..?9])
    |> String.downcase()
    |> String.replace(~r/@[\w\.]+/, "")
    |> String.split(~r/\W+/, trim: true)
    |> Enum.take(8)
    |> Enum.join("-")
    |> Kernel.<>(".md")
  end
end
