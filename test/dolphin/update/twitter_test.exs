defmodule Dolphin.Update.TwitterTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Twitter

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
  end
end
