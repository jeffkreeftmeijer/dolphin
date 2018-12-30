defmodule FrontMatter do
  @doc ~S'''
  Encodes content with metadata into a document with front matter.

  ## Examples

      iex> FrontMatter.encode(
      ...>   "Encodes content with metadata into a document with front matter.",
      ...>   %{
      ...>     date: "2018-12-27",
      ...>     twitter: ["https://twitter.com/jkreeftmeijer/status/1075481362407350272"]
      ...>   }
      ...> )
      {
        :ok,
        """
        ---
        date: 2018-12-27
        twitter: ["https://twitter.com/jkreeftmeijer/status/1075481362407350272"]
        ---
        Encodes content with metadata into a document with front matter.
        """
      }

      iex> FrontMatter.encode(
      ...>   "Encodes content without metadata into a document without front matter.",
      ...>   %{}
      ...> )
      {
        :ok,
        """
        Encodes content without metadata into a document without front matter.
        """
      }

      iex> FrontMatter.encode(
      ...>   "Does not include empty metadata keys in the front matter.",
      ...>   %{date: nil, text: "", twitter: []}
      ...> )
      {
        :ok,
        """
        Does not include empty metadata keys in the front matter.
        """
      }
  '''
  def encode(content, metadata) do
    filtered_metadata =
      metadata
      |> Enum.reject(&empty_value?/1)
      |> Enum.into(%{})

    do_encode(content, filtered_metadata)
  end

  def encode!(content, metadata) do
    {:ok, document} = encode(content, metadata)
    document
  end

  @doc ~S'''
  Decodes a document with front matter into content and metadata.

  ## Examples

      iex> FrontMatter.decode(
      ...> """
      ...> ---
      ...> date: 2018-12-27
      ...> twitter: ["https://twitter.com/jkreeftmeijer/status/1075780054771060736", "https://twitter.com/jkreeftmeijer/status/1075780055907725312"]
      ...> ---
      ...> Decodes a document with front matter into content and metadata.
      ...> """
      ...> )
      {
        :ok,
        %{
          "date" => "2018-12-27",
          "twitter" => ["https://twitter.com/jkreeftmeijer/status/1075780054771060736", "https://twitter.com/jkreeftmeijer/status/1075780055907725312"]
        },
        "Decodes a document with front matter into content and metadata."
      }
  '''
  def decode(document) do
    [_, front_matter, content] = String.split(document, "---\n", parts: 3)

    metadata =
      front_matter
      |> String.trim()
      |> decode_front_matter()

    {:ok, metadata, String.trim(content)}
  end

  defp do_encode(content, metadata) when metadata == %{} do
    {:ok, content <> "\n"}
  end

  defp do_encode(content, metadata) do
    front_matter =
      metadata
      |> Enum.map(fn {key, value} -> to_string(key) <> ": " <> value_to_string(value) end)
      |> Enum.join("\n")

    {
      :ok,
      """
      ---
      #{front_matter}
      ---
      #{content}
      """
    }
  end

  defp decode_front_matter(front_matter) do
    front_matter
    |> String.split("\n")
    |> decode_front_matter(%{})
  end

  defp decode_front_matter([head | tail], acc) do
    [key, value] = String.split(head, ": ", parts: 2)
    decode_front_matter(tail, Map.put(acc, key, decode_value(value)))
  end

  defp decode_front_matter([], acc) do
    acc
  end

  defp value_to_string(value) when is_binary(value), do: value
  defp value_to_string(value), do: inspect(value)

  defp empty_value?({_, nil}), do: true
  defp empty_value?({_, ""}), do: true
  defp empty_value?({_, []}), do: true
  defp empty_value?({_, _}), do: false

  defp decode_value("[\"" <> _ = value) do
    value
    |> String.replace_leading("[\"", "")
    |> String.replace_trailing("\"]", "")
    |> String.split("\", \"", trim: true)
  end

  defp decode_value(value), do: value
end
