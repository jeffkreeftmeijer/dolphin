defmodule Smarty do
  @doc ~S"""
  Performs the following transformations:

  - Straight quotes ( " and ' ) into “curly” quotes
  - Backticks-style quotes (``like this'') into “curly” quotes
  - Dashes (“--” and “---”) into en- and em-dashes
  - Three consecutive dots (“...”) into an ellipses

  ## Examples
  #
      iex> Smarty.convert!("Curly 'single' and \"double\" quotes.")
      "Curly ‘single’ and “double” quotes."

      iex> Smarty.convert!("Curly ``double`` quotes.")
      "Curly “double” quotes."

      iex> Smarty.convert!("En-dashes (--) and em-dashes (---).")
      "En-dashes (–) and em-dashes (—)."

      iex> Smarty.convert!("And ... ellipses.")
      "And … ellipses."

      iex> Smarty.convert!("It's an apostrophe!")
      "It’s an apostrophe!"
  """
  def convert!(text) do
    text
    |> replace(~r/'([^']+)'/, "‘\\1’")
    |> replace(~r/("|``)([^']+)("|``)/, "“\\2”")
    |> replace("'", "’")
    |> replace("---", "—")
    |> replace("--", "–")
    |> replace("...", "…")
  end

  defp replace(text, pattern, replacement) when is_binary(pattern) do
    String.replace(text, pattern, replacement)
  end

  defp replace(text, pattern, replacement) do
    Regex.replace(pattern, text, replacement)
  end
end
