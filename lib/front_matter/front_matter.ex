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

  def encode!(content, metadata) do
    {:ok, document} = encode(content, metadata)
    document
  end

  defp value_to_string(value) when is_binary(value), do: value
  defp value_to_string(value), do: inspect(value)

  defp empty_value?({_, nil}), do: true
  defp empty_value?({_, ""}), do: true
  defp empty_value?({_, []}), do: true
  defp empty_value?({_, _}), do: false
end
