defmodule Dolphin.Update do
  defstruct in_reply_to: nil, text: ""
  alias Dolphin.Update.Github

  @date Application.get_env(:dolphin, :date, Date)

  def from_params(update) do
    update
    |> Enum.reduce(%Dolphin.Update{}, fn {key, value}, acc ->
      Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  def post(%Dolphin.Update{} = update) do
    Github.post(update)
  end

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

  @doc ~S"""
  Extracts the metadata from an update.

  ## Example

      iex> Dolphin.Update.metadata(
      ...>   %Dolphin.Update{
      ...>     text: "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!",
      ...>     in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
      ...>   }
      ...> )
      %{in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"}

  """
  def metadata(%{in_reply_to: in_reply_to}) do
    %{in_reply_to: in_reply_to}
  end

  def metadata(_), do: %{}
end
