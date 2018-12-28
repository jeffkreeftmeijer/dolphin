defmodule FakeTwitter do
  def start_link() do
    Agent.start_link(fn -> %{updates: []} end, name: __MODULE__)
  end

  def updates do
    Agent.get(__MODULE__, &Map.get(&1, :updates))
  end

  def update(status, options \\ []) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn %{updates: updates} = state ->
        %{state | updates: [{status, options} | updates]}
      end)
    end

    %{id: id(status), text: status}
  end

  defp id(status) do
    sum =
      status
      |> to_charlist
      |> Enum.sum()

    10000 + sum
  end
end
