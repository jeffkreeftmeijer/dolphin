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

    test "does smartypants conversions" do
      assert {:ok, %Twitter{content: "I’ll start testing these tips in Vim 8."}} =
               Twitter.from_update(%Update{text: "I'll start testing these tips in Vim 8."})
    end

    test "is invalid for a non-Twitter reply" do
      assert {:error, :invalid_in_reply_to} =
               Twitter.from_update(%Update{
                 in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
               })
    end

    test "is invalid with a non-Twitter mention" do
      assert {:error, :invalid_mention} =
               Twitter.from_update(%Update{
                 text:
                   "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!"
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
  end
end
