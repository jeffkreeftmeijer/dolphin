defmodule Dolphin.Update do
  defstruct text: "",
            date: nil,
            in_reply_to: nil,
            twitter: nil,
            mastodon: nil,
            media: [],
            services: []

  alias Dolphin.{Update, Update.Github, Update.Twitter, Update.Mastodon}

  @date Application.get_env(:dolphin, :date, Date)
  @datetime Application.get_env(:dolphin, :datetime, DateTime)

  def from_params(update) do
    update
    |> Enum.reduce(%Update{}, fn {key, value}, acc ->
      Map.put(acc, String.to_existing_atom(key), value)
    end)
  end

  def post(%Update{} = update) do
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
      Github.post(%{
        update
        | twitter: twitter_links,
          mastodon: mastodon_links,
          date: @datetime.to_iso8601(@datetime.utc_now)
      })

    {:ok,
     %{
       github: github_links,
       twitter: twitter_links,
       mastodon: mastodon_links
     }}
  end

  @doc ~S"""
  Generates a file name based on today's date and the update's text.

  ## Examples

      iex> Dolphin.Update.filename(%Dolphin.Update{text: "$ man ed\n\n#currentstatus"})
      "2018-12-27-man-ed-currentstatus.md"
      iex> Dolphin.Update.filename(%Dolphin.Update{text: "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!"})
      "2018-12-27-because-ed-is-the-standard.md"
      iex> Dolphin.Update.filename(%Dolphin.Update{text: "<https://w3.org/TR/activitypub>\n\n#currentstatus"})
      "2018-12-27-https-w3-org-tr-activitypub.md"
      iex> Dolphin.Update.filename(%Dolphin.Update{text: "String.replace(text, ~r/(?<!\!)\[([^\]]+)\]\(([^\)]+)\)/, \"\\1 (\\2)\")"})
      "2018-12-27-string-replace-text-r-1.md"

  """
  def filename(%Update{text: text}) do
    (@date.to_iso8601(@date.utc_today) <> "-" <> text)
    |> Dolphin.Utils.filter_characters([
      ' ',
      '\n',
      '-',
      '@',
      '/',
      '.',
      '(',
      ')',
      ?a..?z,
      ?A..?Z,
      ?0..?9
    ])
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
      ...>     date: ~N[2018-12-27 15:46:23] |> DateTime.from_naive!("Etc/UTC"),
      ...>     in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208",
      ...>     twitter: ["https://twitter.com/jkreeftmeijer/status/1075481362407350272"],
      ...>     mastodon: ["https://mastodon.social/@jkreeftmeijer/101195179464343851"],
      ...>   }
      ...> )
      %{
        date: ~N[2018-12-27 15:46:23] |> DateTime.from_naive!("Etc/UTC"),
        in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208",
        twitter: ["https://twitter.com/jkreeftmeijer/status/1075481362407350272"],
        mastodon: ["https://mastodon.social/@jkreeftmeijer/101195179464343851"],
      }

  """
  def metadata(update) do
    Map.take(update, [:date, :in_reply_to, :twitter, :mastodon])
  end

  @doc ~S"""
  Replaces markdown links.

  ## Example

      iex> Dolphin.Update.replace_markdown_links("<https://mastodon.social/@jkreeftmeijer/101236371751163533>")
      "https://mastodon.social/@jkreeftmeijer/101236371751163533"
      iex> Dolphin.Update.replace_markdown_links("[Mastodon](https://mastodon.social)")
      "Mastodon (https://mastodon.social)"
      iex> Dolphin.Update.replace_markdown_links("![An image.](file.jpg)")
      "![An image.](file.jpg)"

  """
  def replace_markdown_links(update) do
    update
    |> String.replace(~r/\<(http[^>]+)\>/, "\\1")
    |> String.replace(~r/(?<!\!)\[([^\]]+)\]\(([^\)]+)\)/, "\\1 (\\2)")
  end

  @doc ~S"""
  Removes markdown image tags matching media uploads.

  ## Example

      iex> Dolphin.Update.remove_media_image_tags(
      ...>   "Image.\n\n![A file.](/media/file.jpg)\n\nThat’s all!",
      ...>   [{%Plug.Upload{filename: "file.jpg"}, "A file."}]
      ...> )
      "Image.\n\nThat’s all!"

  """
  def remove_media_image_tags(content, [{%{filename: filename}, alt} | tail]) do
    remove_media_image_tags(
      String.replace(content, ~r/\s*!\[#{alt}\]\(\/media\/#{filename}\)/, ""),
      tail
    )
  end

  def remove_media_image_tags(content, []), do: content
end
