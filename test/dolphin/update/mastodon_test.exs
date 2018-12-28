defmodule Dolphin.Update.MastodonTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Mastodon

  describe "from_update/1" do
    test "creates a Mastodon update from an Update" do
      assert Dolphin.Update.Mastodon.from_update(%Dolphin.Update{
               text: "$ man ed\n\n#currentstatus"
             }) == %Dolphin.Update.Mastodon{content: "$ man ed\n\n#currentstatus"}
    end

    test "finds the in_reply_to_id from a web client URL" do
      assert %Dolphin.Update.Mastodon{in_reply_to_id: "101195085216392589"} =
               Dolphin.Update.Mastodon.from_update(%Dolphin.Update{
                 in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
               })
    end

    test "finds the in_reply-to_id from an instance URL" do
      assert %Dolphin.Update.Mastodon{in_reply_to_id: "101275229107919444"} =
               Dolphin.Update.Mastodon.from_update(%Dolphin.Update{
                 in_reply_to: "https://ruby.social/@solnic/101275229051824324"
               })
    end
  end
end
