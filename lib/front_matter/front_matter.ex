defmodule FrontMatter do
  @doc ~S'''
  Encodes content with metadata into a document with front matter.

  ## Examples

      iex> FrontMatter.encode(
      ...>   "Encodes content with metadata into a document with front matter.",
      ...>   %{date: "2018-12-27"}
      ...> )
      {
        :ok,
        """
        ---
        date: 2018-12-27
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
  '''
  def encode(content, metadata) when metadata == %{} do
    {:ok, content <> "\n"}
  end

  def encode(content, metadata) do
    front_matter =
      metadata
      |> Enum.map(fn {key, value} -> to_string(key) <> ": " <> value end)
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

end
