defmodule Dolphin.Update.MastodonTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Mastodon
  alias Dolphin.{Update, Update.Mastodon}
  import TestUtils

  describe "configured?/0" do
    test "is configured with mastodon credentials" do
      assert Mastodon.configured?()
    end

    test "is not configured without mastodon credentials" do
      without_configuration(:dolphin, :mastodon_credentials, fn ->
        refute Mastodon.configured?()
      end)
    end
  end

  describe "from_update/1" do
    test "creates a Mastodon update from an Update" do
      assert Mastodon.from_update(%Update{text: "$ man ed\n\n#currentstatus"}) ==
               {:ok,
                %Mastodon{
                  content: "$ man ed\n\n#currentstatus"
                }}
    end

    test "finds the in_reply_to_id from a web client URL" do
      assert {:ok, %Mastodon{in_reply_to_id: "101195085216392589"}} =
               Mastodon.from_update(%Update{
                 in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
               })
    end

    test "finds the in_reply-to_id from an instance URL" do
      assert {:ok, %Mastodon{in_reply_to_id: "101275229107919444"}} =
               Mastodon.from_update(%Update{
                 in_reply_to: "https://ruby.social/@solnic/101275229051824324"
               })
    end

    test "finds the in_reply-to_id from a local path" do
      assert {:ok,
              %Mastodon{
                content: "$ man ed\n\n#currentstatus",
                in_reply_to_id: "101275274281588324"
              }} =
               Mastodon.from_update(%Update{
                 text: "$ man ed\n\n#currentstatus",
                 in_reply_to: "/2018/12/20/you-mean-setting-macros-with.html"
               })
    end

    test "does not try to find  an in_reply_to_id from an empty url" do
      assert {:ok, %Mastodon{in_reply_to_id: nil}} =
               Mastodon.from_update(%Update{in_reply_to: ""})
    end

    test "replaces markdown links" do
      assert {:ok, %Mastodon{content: "Mastodon (https://mastodon.social)"}} =
               Mastodon.from_update(%Update{text: "[Mastodon](https://mastodon.social)"})
    end

    test "is invalid for a non-Mastodon reply" do
      assert {:error, :invalid_in_reply_to} =
               Mastodon.from_update(%Update{
                 in_reply_to: "https://twitter.com/jkreeftmeijer/status/1078710137458700288"
               })
    end

    test "is invalid with a Twitter mention" do
      assert {:error, :invalid_mention} =
               Mastodon.from_update(%Update{
                 text: "@tbdr@twitter.com More convoluted than that, actually. 😅"
               })
    end

    test "splits up updates longer than 500 characters" do
      text = """
      I *love* reinventing the wheel.

      Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.

      While you shouldn’t rely on a hand-rolled HTTP server or a naïve reimplementation of an ancient OTP construct in production, taking software apart and rebuilding it is the best way I know to understand what’s happening under the hood.

      The results aren’t better than what already exists, or implemented in the fewest lines of code. That's not the point. They're built to be as expressive as possible to help explain concepts like HTTP, Rack, or inter-process message passing, and because they're a fun exercise.
      """

      assert {:ok,
              %Mastodon{
                content: "I *love" <> _,
                reply: %Mastodon{content: "The results aren’t" <> _}
              }} = Mastodon.from_update(%Update{text: text})
    end

    test "adds media to the update" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "file.jpg",
        path: "test/file.jpg"
      }

      assert {:ok, %Mastodon{media: [{upload, "A file."}]}} =
               Mastodon.from_update(%Update{text: "![A file.](/media/file.jpg)", media: [upload]})
    end

    test "adds urlencoded media to the update" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "a file.jpg",
        path: "test/a file.jpg"
      }

      assert {:ok, %Mastodon{media: [{upload, "A file."}]}} =
               Mastodon.from_update(%Update{
                 text: "![A file.](/media/a%20file.jpg)",
                 media: [upload]
               })
    end

    test "removes Markdown image tags from the update" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "file.jpg",
        path: "test/file.jpg"
      }

      assert {:ok, %Mastodon{content: "Image.\n\nThat’s all!"}} =
               Mastodon.from_update(%Update{
                 text: "Image.\n\n![A file.](/media/file.jpg)\n\nThat’s all!",
                 media: [upload]
               })
    end

    test "removes urlencoded Markdown image tags from the update" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "a file.jpg",
        path: "test/a file.jpg"
      }

      assert {:ok, %Mastodon{content: "Image.\n\nThat’s all!"}} =
               Mastodon.from_update(%Update{
                 text: "Image.\n\n![A file.](/media/a%20file.jpg)\n\nThat’s all!",
                 media: [upload]
               })
    end

    test "distributes media across updates" do
      uploads =
        [upload_1, upload_2] = [
          %Plug.Upload{
            content_type: "image/jpeg",
            filename: "file1.jpg",
            path: "test/file1.jpg"
          },
          %Plug.Upload{
            content_type: "image/jpeg",
            filename: "file2.jpg",
            path: "test/file2.jpg"
          }
        ]

      assert {:ok, %Mastodon{media: [{^upload_1, _}], reply: %Mastodon{media: [{^upload_2, _}]}}} =
               Mastodon.from_update(%Update{
                 text: "![](/media/file1.jpg)\n\n\n![](/media/file2.jpg)",
                 media: uploads
               })
    end
  end

  describe "post/1" do
    setup do
      FakeMastodon.start_link()
      :ok
    end

    test "posts an update to Mastodon" do
      update = %Mastodon{content: "$ man ed\n\n#currentstatus"}

      expected_url = "https://mastodon.social/@jkreeftmeijer/12119"

      assert Mastodon.post(update) == {:ok, [expected_url]}
      assert FakeMastodon.updates() == [{"$ man ed\n\n#currentstatus", []}]
    end

    test "posts a reply to Mastodon" do
      Mastodon.post(%Mastodon{
        content:
          "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!",
        in_reply_to_id: "101195085216392589"
      })

      assert [{_, [in_reply_to_id: "101195085216392589"]}] = FakeMastodon.updates()
    end

    test "posts a thread to Mastodon" do
      update = %Mastodon{
        content:
          "Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.",
        reply: %Mastodon{
          content:
            "While you shouldn’t rely on a hand-rolled HTTP server or a naïve reimplementation of an ancient OTP construct in production, taking software apart and rebuilding it is the best way I know to understand what’s happening under the hood.",
          reply: %Mastodon{
            content:
              "The results aren’t better than what already exists, or implemented in the fewest lines of code. That's not the point. They're built to be as expressive as possible to help explain concepts like HTTP, Rack, or inter-process message passing, and because they're a fun exercise."
          }
        }
      }

      expected_urls = [
        "https://mastodon.social/@jkreeftmeijer/38905",
        "https://mastodon.social/@jkreeftmeijer/48305",
        "https://mastodon.social/@jkreeftmeijer/43501"
      ]

      assert Mastodon.post(update) == {:ok, expected_urls}

      assert [
               {"Some of my" <> _, []},
               {"While you shouldn’t" <> _, [in_reply_to_id: "38905"]},
               {"The results aren’t" <> _, [in_reply_to_id: "48305"]}
             ] = FakeMastodon.updates()
    end

    test "uploads a file to Mastodon" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "file.jpg",
        path: "test/file.jpg"
      }

      Mastodon.post(%Mastodon{content: "", media: [{upload, "A file."}]})

      assert [{"test/file.jpg", "A file."}] = FakeMastodon.uploads()
      assert [{"", [media_ids: ["9569296"]]}] = FakeMastodon.updates()
    end
  end
end
