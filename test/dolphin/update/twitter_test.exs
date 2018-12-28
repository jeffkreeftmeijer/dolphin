defmodule Dolphin.Update.TwitterTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Twitter

  describe "from_update/1" do
    test "creates a Twitter update from an Update" do
      assert Dolphin.Update.Twitter.from_update(%Dolphin.Update{
               text: "$ man ed\n\n#currentstatus"
             }) == %Dolphin.Update.Twitter{content: "$ man ed\n\n#currentstatus"}
    end
  end
end
