defmodule Dolphin.Update.TwitterTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Twitter
  alias Dolphin.{Update, Update.Twitter}

  @credentials Application.get_env(:dolphin, :twitter_credentials)
  @username @credentials[:username]

  setup do
    FakeTwitter.start_link()
    :ok
  end

  describe "from_update/1" do
    test "creates a Twitter update from an Update" do
      assert Twitter.from_update(%Update{text: "$ man ed\n\n#currentstatus"}) ==
               {:ok, %Twitter{content: "$ man ed\n\n#currentstatus"}}
    end

    test "finds the in_reply_to_id for a reply" do
      assert {:ok, %Twitter{in_reply_to_id: "1075477062360670208"}} =
               Twitter.from_update(%Update{
                 text: "@tbdr@twitter.com More convoluted than that, actually. 😅",
                 in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208"
               })
    end

    test "replaces mentions with Twitter-style ones" do
      assert {:ok, %Twitter{content: "@tbdr More convoluted than that, actually. 😅"}} =
               Twitter.from_update(%Update{
                 text: "@tbdr@twitter.com More convoluted than that, actually. 😅",
                 in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208"
               })
    end

    test "finds the in_reply-to_id from a local path" do
      assert {:ok,
              %Twitter{
                content: "$ man ed\n\n#currentstatus",
                in_reply_to_id: "1076438296782426112"
              }} =
               Twitter.from_update(%Update{
                 text: "$ man ed\n\n#currentstatus",
                 in_reply_to: "/2018/12/22/also-the-autowrite-and-autowriteall.html"
               })
    end

    test "replaces markdown links" do
      assert {:ok, %Twitter{content: "Mastodon (https://mastodon.social)"}} =
               Twitter.from_update(%Update{text: "[Mastodon](https://mastodon.social)"})
    end

    test "is invalid for a non-Twitter reply" do
      assert {:error, :invalid_in_reply_to} =
               Twitter.from_update(%Update{
                 in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
               })
    end

    test "is invalid as a reply to a local path that wasn't posted to Twitter" do
      assert {:error, :invalid_in_reply_to} =
               Twitter.from_update(%Update{
                 in_reply_to: "/2018/12/20/you-mean-setting-macros-with.html"
               })
    end

    test "is invalid with a non-Twitter mention" do
      assert {:error, :invalid_mention} =
               Twitter.from_update(%Update{
                 text:
                   "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!"
               })
    end

    test "splits up updates longer than 280 characters" do
      text = """
      I *love* reinventing the wheel.

      Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.

      While you shouldn’t rely on a hand-rolled HTTP server or a naïve reimplementation of an ancient OTP construct in production, taking software apart and rebuilding it is the best way I know to understand what’s happening under the hood.

      The results aren’t better than what already exists, or implemented in the fewest lines of code. That's not the point. They're built to be as expressive as possible to help explain concepts like HTTP, Rack, or inter-process message passing, and because they're a fun exercise.
      """

      assert {:ok,
              %Twitter{
                content: "I *love" <> _,
                reply: %Twitter{
                  content: "While you" <> _,
                  reply: %Twitter{content: "The results aren’t" <> _}
                }
              }} = Twitter.from_update(%Update{text: text})
    end

    test "adds media to the update" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "file.jpg",
        path: "test/file.jpg"
      }

      assert {:ok, %Twitter{media: [{upload, "A file."}]}} =
               Twitter.from_update(%Update{text: "![A file.](/media/file.jpg)", media: [upload]})
    end

    test "removes Markdown image tags from the update" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "file.jpg",
        path: "test/file.jpg"
      }

      assert {:ok, %Twitter{content: "Image.\n\nThat’s all!"}} =
               Twitter.from_update(%Update{
                 text: "Image.\n\n![A file.](/media/file.jpg)\n\nThat’s all!",
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

      assert {:ok, %Twitter{media: [{^upload_1, _}], reply: %Twitter{media: [{^upload_2, _}]}}} =
               Twitter.from_update(%Update{
                 text: "![](/media/file1.jpg)\n\n\n![](/media/file2.jpg)",
                 media: uploads
               })
    end
  end

  describe "post/1" do
    test "posts an update to Twitter" do
      update = %Twitter{content: "$ man ed\n\n#currentstatus"}

      expected_url = "https://twitter.com/#{@username}/status/12119"

      assert Twitter.post(update) == {:ok, [expected_url]}
      assert FakeTwitter.updates() == [{"$ man ed\n\n#currentstatus", []}]
    end

    test "posts a reply to Twitter" do
      Twitter.post(%Twitter{
        content: "@tbdr@twitter.com More convoluted than that, actually. 😅",
        in_reply_to_id: "1075477062360670208"
      })

      assert [{_, [in_reply_to_status_id: "1075477062360670208"]}] = FakeTwitter.updates()
    end

    test "posts a thread to Twitter" do
      update = %Twitter{
        content:
          "Some of my articles explain how to build your own GenServer in Elixir or how to compare images in plain Ruby, and I’ve built minimal clones of libraries like RSpec and Spring in the past to understand and teach how they work.",
        reply: %Twitter{
          content:
            "While you shouldn’t rely on a hand-rolled HTTP server or a naïve reimplementation of an ancient OTP construct in production, taking software apart and rebuilding it is the best way I know to understand what’s happening under the hood.",
          reply: %Twitter{
            content:
              "The results aren’t better than what already exists, or implemented in the fewest lines of code. That's not the point. They're built to be as expressive as possible to help explain concepts like HTTP, Rack, or inter-process message passing, and because they're a fun exercise."
          }
        }
      }

      expected_urls = [
        "https://twitter.com/#{@username}/status/38905",
        "https://twitter.com/#{@username}/status/48305",
        "https://twitter.com/#{@username}/status/43501"
      ]

      assert Twitter.post(update) == {:ok, expected_urls}

      assert [
               {"Some of my" <> _, []},
               {"While you shouldn’t" <> _, [in_reply_to_status_id: 38905]},
               {"The results aren’t" <> _, [in_reply_to_status_id: 48305]}
             ] = FakeTwitter.updates()
    end

    test "uploads a file to Twitter" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "file.jpg",
        path: "test/file.jpg"
      }

      Twitter.post(%Twitter{content: "", media: [{upload, "A file."}]})

      assert [{"test/file.jpg", "image/jpeg"}] = FakeTwitter.uploads()
      assert [{"", [media_ids: [1_079_531_587_988_082_688]]}] = FakeTwitter.updates()
    end
  end
end
