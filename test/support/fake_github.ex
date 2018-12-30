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

  def find(_client, _username, _repository, "2018-12-22-also-the-autowrite-and-autowriteall.md") do
    {200,
     %{
       "content" => """
       LS0tCmRhdGU6IDIwMTgtMTItMjJUMTE6MjQ6MjhaCmluX3JlcGx5X3RvOiBodHRwczovL3R3a
       XR0ZXIuY29tL2NoYXN0ZWxsL3N0YXR1cy8xMDc2MDQ2Nzg0NTQyMTgzNDI0CnR3aXR0ZXI6IF
       siaHR0cHM6Ly90d2l0dGVyLmNvbS9qa3JlZWZ0bWVpamVyL3N0YXR1cy8xMDc2NDM4Mjk2Nzg
       yNDI2MTEyIl0KLS0tCkBjaGFzdGVsbEB0d2l0dGVyLmNvbSBBbHNvLCB0aGUgYGF1dG93cml0
       ZWAgYW5kIGBhdXRvd3JpdGVhbGxgIG9wdGlvbnMgc2F2ZSB0aGUgZmlsZSB3aGVuIHN3aXRja
       GluZyBidWZmZXJzIG9yIHF1aXR0aW5nLCB3aGljaCBjb3ZlcnMgY2FzZXMgd2hlcmUgdGhlIG
       ZpbGUgaXMgY2hhbmdlZCB3aXRob3V0IHN3aXRjaGluZyBtb2Rlcy4KCklkZWFsbHksIGl0J2Q
       ganVzdCBzYXZlIHdoZW5ldmVyIGAmbW9kaWZpZWRgIGlzIDEsIGJ1dCBJIGhhdmVuJ3QgZm91
       bmQgYSB3YXkgdG8gaG9vayBpbiB5ZXQuIPCfpJQK
       """
     }, %HTTPoison.Response{}}
  end

  def find(_client, _username, _repository, "2018-12-20-you-mean-setting-macros-with.md") do
    {200,
     %{
       "content" => """
       LS0tCmRhdGU6IDIwMTgtMTItMjBUMjA6MzQ6MDdaCmluX3JlcGx5X3RvOiBodHRwczovL3J1Y
       nkuc29jaWFsL0Bzb2xuaWMvMTAxMjc1MjI5MDUxODI0MzI0Cm1hc3RvZG9uOiBbImh0dHBzOi
       8vbWFzdG9kb24uc29jaWFsL0Bqa3JlZWZ0bWVpamVyLzEwMTI3NTI3NDI4MTU4ODMyNCJdCi0
       tLQpAc29sbmljQHJ1Ynkuc29jaWFsIFlvdSBtZWFuIHNldHRpbmcgbWFjcm9zIHdpdGggYHE8
       bGV0dGVyPjxjb21tYW5kcz5xYCwgcmlnaHQ/IE5vdCBtdWNoIGV4cGVyaWVuY2Ugd2l0aCBtY
       WNyb3MsIGJlY2F1c2UgdGhleSBhbHdheXMgdGFrZSBhIGxvdCBvZiB0aW1lIHRvIGdldCByaW
       dodCBmb3IgbWUuIPCfmIUKClRoZXnigJl2ZSBiZWVuIG9uIHRvcCBvZiBteSBsaXN0IHRvIHB
       yb3Blcmx5IGZpZ3VyZSBvdXQgZm9yIHllYXJzLCB0aG91Z2guCg==
       """
     }, %HTTPoison.Response{}}
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
