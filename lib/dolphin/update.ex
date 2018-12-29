defmodule Dolphin.Update do
  defstruct text: "", in_reply_to: nil, twitter: nil, mastodon: nil
  alias Dolphin.Update.{Github, Twitter, Mastodon}

  @date Application.get_env(:dolphin, :date, Date)

  def from_params(update) do
    update
    |> Enum.reduce(%Dolphin.Update{}, fn {key, value}, acc ->
      Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  def post(%Dolphin.Update{} = update) do
    twitter_links =
      case Twitter.post(update) do
        {:ok, links} -> links
        _ -> []
      end

    mastodon_links =
      case Mastodon.post(update) do
        {:ok, links} -> links
        _ -> []
      end

    {:ok, github_links} =
      Github.post(%{update | twitter: twitter_links, mastodon: mastodon_links})

    {:ok, %{github: github_links, twitter: twitter_links, mastodon: mastodon_links}}
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
      ...>     text: "@tbdr@twitter.com More convoluted than that, actually. 😅",
      ...>     in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208",
      ...>     twitter: ["https://twitter.com/jkreeftmeijer/status/1075481362407350272"],
      ...>     mastodon: ["https://mastodon.social/@jkreeftmeijer/101195179464343851"]
      ...>   }
      ...> )
      %{in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208", twitter: ["https://twitter.com/jkreeftmeijer/status/1075481362407350272"], mastodon: ["https://mastodon.social/@jkreeftmeijer/101195179464343851"]}

  """
  def metadata(update) do
    Map.take(update, [:in_reply_to, :twitter, :mastodon])
  end
end
