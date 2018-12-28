defmodule Dolphin.Update.TwitterTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Twitter

  @credentials Application.get_env(:dolphin, :twitter_credentials)
  @username @credentials[:username]

  setup do
    FakeTwitter.start_link()
    :ok
  end

  describe "from_update/1" do
    test "creates a Twitter update from an Update" do
      assert Dolphin.Update.Twitter.from_update(%Dolphin.Update{
               text: "$ man ed\n\n#currentstatus"
             }) == %Dolphin.Update.Twitter{content: "$ man ed\n\n#currentstatus"}
    end

    test "finds the in_reply_to_id for a reply" do
      assert %Dolphin.Update.Twitter{in_reply_to_id: "1075477062360670208"} =
               Dolphin.Update.Twitter.from_update(%Dolphin.Update{
                 text: "@tbdr@twitter.com More convoluted than that, actually. 😅",
                 in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208"
               })
    end

    test "replaces mentions with Twitter-style ones" do
      assert %Dolphin.Update.Twitter{content: "@tbdr More convoluted than that, actually. 😅"} =
               Dolphin.Update.Twitter.from_update(%Dolphin.Update{
                 text: "@tbdr@twitter.com More convoluted than that, actually. 😅",
                 in_reply_to: "https://twitter.com/tbdr/status/1075477062360670208"
               })
    end
  end

  describe "post/1" do
    test "posts an update to Twitter" do
      update = %Dolphin.Update{text: "$ man ed\n\n#currentstatus"}

      expected_url = "https://twitter.com/#{@username}/status/12119"

      assert Dolphin.Update.Twitter.post(update) == {:ok, [expected_url]}
      assert FakeTwitter.updates() == ["$ man ed\n\n#currentstatus"]
    end
  end
end
