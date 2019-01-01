defmodule FakeTwitter do
  def start_link() do
    Agent.start_link(fn -> %{updates: [], uploads: [], alts: []} end, name: __MODULE__)
  end

  def updates do
    Agent.get(__MODULE__, &Map.get(&1, :updates))
  end

  def uploads do
    Agent.get(__MODULE__, &Map.get(&1, :uploads))
  end

  def alts do
    Agent.get(__MODULE__, &Map.get(&1, :alts))
  end

  def update(status, options \\ []) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn %{updates: updates} = state ->
        %{state | updates: updates ++ [{status, options}]}
      end)
    end

    %{id: id(status), text: status}
  end

  def upload_media(filename, content_type) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn %{uploads: uploads} = state ->
        %{state | uploads: uploads ++ [{filename, content_type}]}
      end)
    end

    1_079_531_587_988_082_688
  end

  def set_media_alt(media_id, alt) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn %{alts: alts} = state ->
        %{state | alts: alts ++ [{media_id, alt}]}
      end)
    end

    :ok
  end

  defp id(status) do
    sum =
      status
      |> to_charlist
      |> Enum.sum()

    10000 + sum
  end
end
