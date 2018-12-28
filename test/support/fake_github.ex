defmodule FakeGithub.Client do
  def new(credentials), do: Tentacat.Client.new(credentials)
end

defmodule FakeGithub.Contents do
  def start_link() do
    Agent.start_link(fn -> %{files: []} end, name: __MODULE__)
  end

  def files do
    Agent.get(__MODULE__, &Map.get(&1, :files))
  end

  def create(_client, username, repository, filename, body) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn %{files: files} = state ->
        {:ok, content} = Base.decode64(body["content"])
        %{state | files: [content | files]}
      end)
    end

    {201,
     %{
       "commit" => %{
         "message" => "Add " <> filename
       },
       "content" => %{
         "_links" => %{
           "html" =>
             "https://github.com/" <> username <> "/" <> repository <> "/blob/master/" <> filename
         }
       }
     }, %HTTPoison.Response{}}
  end
end
