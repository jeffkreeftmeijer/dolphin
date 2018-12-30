defmodule FakeHTTPoison do
  def get(
        "https://raw.githubusercontent.com/jeffkreeftmeijer/updates/master/2018-12-20-you-mean-setting-macros-with.md"
      ) do
    {:ok,
     %HTTPoison.Response{
       body: """
       ---
       date: 2018-12-20T20:34:07Z
       in_reply_to: https://ruby.social/@solnic/101275229051824324
       mastodon: ["https://mastodon.social/@jkreeftmeijer/101275274281588324"]
       ---
       @solnic@ruby.social You mean setting macros with `q<letter><commands>q`, right? Not much experience with macros, because they always take a lot of time to get right for me. 😅

       They’ve been on top of my list to properly figure out for years, though.
       """,
       headers: [],
       status_code: 200
     }}
  end
end
