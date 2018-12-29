defmodule Dolphin.Update.Twitter do
  defstruct [:content, :in_reply_to_id]
  alias Dolphin.Update

  @twitter Application.get_env(:dolphin, :twitter, ExTwitter)
  @credentials Application.get_env(:dolphin, :twitter_credentials)
  @username @credentials[:username]

  def from_update(%Update{} = update) do
    from_update(update, %Dolphin.Update.Twitter{})
  end

  defp from_update(%Update{in_reply_to: url} = update, acc) when is_binary(url) and url != "" do
    case Regex.run(~r/https:\/\/twitter.com\/\w+\/status\/(\d+)/, url) do
      [_, in_reply_to_id] ->
        from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})

      _ ->
        {:error, :invalid_in_reply_to}
    end
  end

  defp from_update(%Update{text: text}, acc) do
    {:ok, %{acc | content: replace_mentions(text)}}
  end

  def post(%Dolphin.Update.Twitter{content: content, in_reply_to_id: in_reply_to_id})
      when in_reply_to_id != nil do
    %{id: id} = @twitter.update(content, in_reply_to_status_id: in_reply_to_id)

    {:ok, ["https://twitter.com/#{@username}/status/#{id}"]}
  end

  def post(%Dolphin.Update.Twitter{content: content}) do
    %{id: id} = @twitter.update(content)

    {:ok, ["https://twitter.com/#{@username}/status/#{id}"]}
  end

  def post(%Update{} = update) do
    case from_update(update) do
      {:ok, update} -> post(update)
      {:error, _} = error -> error
    end
  end

  defp replace_mentions(text) do
    Regex.replace(~r/@(\w+)@twitter.com/, text, "@\\1")
  end
end
