defmodule FakeGithub.Client do
  def new(credentials), do: Tentacat.Client.new(credentials)
end

defmodule FakeGithub.Contents do
  def create(_client, username, repository, filename, _body) do
    {201,
     %{
       "commit" => %{
         "message" => "Add " <> filename
       },
       "content" => %{
         "_links" => %{
           "html" => "https://github.com/" <> username <> "/" <> repository <> "/blob/master/" <> filename
         }
       }
     }, %HTTPoison.Response{}}
  end
end
