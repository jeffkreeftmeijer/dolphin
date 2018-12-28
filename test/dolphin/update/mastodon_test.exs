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

  describe "post/1" do
    setup do
      FakeMastodon.start_link()
      :ok
    end

    test "posts an update to Mastodon" do
      update = %Dolphin.Update{text: "$ man ed\n\n#currentstatus"}

      expected_url = "https://mastodon.social/@jkreeftmeijer/12119"

      assert Dolphin.Update.Mastodon.post(update) == {:ok, [expected_url]}
      assert FakeMastodon.updates() == [{"$ man ed\n\n#currentstatus", []}]
    end

    test "posts a reply to Mastodon" do
      Dolphin.Update.Mastodon.post(%Dolphin.Update{
        text:
          "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!",
        in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
      })

      assert [{_, [in_reply_to_status_id: "101195085216392589"]}] = FakeMastodon.updates()
    end
  end
end
