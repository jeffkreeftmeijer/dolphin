defmodule FakeMastodon do
  def start_link() do
    Agent.start_link(fn -> %{updates: []} end, name: __MODULE__)
  end

  def updates do
    Agent.get(__MODULE__, &Map.get(&1, :updates))
  end

  def create_status(_conn, status, options \\ []) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn %{updates: updates} = state ->
        %{state | updates: [{status, options} | updates]}
      end)
    end

    %{url: "https://mastodon.social/@jkreeftmeijer/#{id(status)}"}
  end

  def search(_conn, "https://ruby.social/@solnic/101275229051824324") do
    %Hunter.Result{
      accounts: [],
      hashtags: [],
      statuses: [
        %Hunter.Status{
          id: "101275229107919444"
        }
      ]
    }
  end

  defp id(status) do
    sum =
      status
      |> to_charlist
      |> Enum.sum()

    10000 + sum
  end
end
