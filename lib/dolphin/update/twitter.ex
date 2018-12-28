defmodule Dolphin.Update.Twitter do
  defstruct [:content, :in_reply_to_id]
  alias Dolphin.Update

  def from_update(%Update{} = update) do
    from_update(update, %Dolphin.Update.Twitter{})
  end

  defp from_update(%Update{in_reply_to: url} = update, acc) when is_binary(url) do
    [_, in_reply_to_id] = Regex.run(~r/https:\/\/twitter.com\/\w+\/status\/(\d+)/, url)

    from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})
  end

  defp from_update(%Update{text: text}, acc) do
    %{acc | content: replace_mentions(text)}
  end

  defp replace_mentions(text) do
    Regex.replace(~r/@(\w+)@twitter.com/, text, "@\\1")
  end
end
