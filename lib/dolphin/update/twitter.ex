defmodule Dolphin.Update.Twitter do
  defstruct [:content, :in_reply_to_id]
  alias Dolphin.Update

  def from_update(%Update{text: text, in_reply_to: url}) when is_binary(url) do
    [_, in_reply_to_id] = Regex.run(~r/https:\/\/twitter.com\/\w+\/status\/(\d+)/, url)

    %Dolphin.Update.Twitter{content: text, in_reply_to_id: in_reply_to_id}
  end

  def from_update(%Update{text: text}) do
    %Dolphin.Update.Twitter{content: text}
  end
end
