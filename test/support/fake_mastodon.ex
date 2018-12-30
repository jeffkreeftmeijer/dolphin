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
        %{state | updates: updates ++ [{status, options}]}
      end)
    end

    id = id(status)
    %{id: "#{id}", url: "https://mastodon.social/@jkreeftmeijer/#{id}"}
  end

  def search(_conn, "https://ruby.social/@solnic/101275229051824324") do
    %Hunter.Result{
      accounts: [],
      hashtags: [],
      statuses: [%Hunter.Status{id: "101275229107919444"}]
    }
  end

  def search(_conn, "https://mastodon.social/@jkreeftmeijer/101275274281588324") do
    %Hunter.Result{
      accounts: [],
      hashtags: [],
      statuses: [%Hunter.Status{id: "101275274281588324"}]
    }
  end

  def search(_conn, _) do
    %Hunter.Result{
      accounts: [],
      hashtags: [],
      statuses: []
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
