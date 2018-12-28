defmodule Dolphin.Update.GithubTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Github

  @credentials Application.get_env(:dolphin, :github_credentials)
  @username @credentials[:username]
  @repository @credentials[:repository]

  setup do
    FakeGithub.Contents.start_link()
    :ok
  end

  describe "from_update/1" do
    test "creates a Github update from an Update" do
      assert Dolphin.Update.Github.from_update(%Dolphin.Update{
               text: "$ man ed\n\n#currentstatus"
             }) ==
               %Dolphin.Update.Github{
                 filename: "2018-12-27-man-ed-currentstatus.md",
                 content: "$ man ed\n\n#currentstatus\n"
               }
    end

    test "creates a Github reply from an Update" do
      assert Dolphin.Update.Github.from_update(%Dolphin.Update{
               text:
                 "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!",
               in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
             }) ==
               %Dolphin.Update.Github{
                 filename: "2018-12-27-because-ed-is-the-standard.md",
                 content: """
                 ---
                 in_reply_to: https://mastodon.social/web/statuses/101195085216392589
                 ---
                 @judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!
                 """
               }
    end
  end

  describe "post/1" do
    test "posts a file to a Github repository" do
      response = Dolphin.Update.Github.post(%Dolphin.Update{text: "$ man ed\n\n#currentstatus"})

      assert {201,
              %{
                "commit" => %{"message" => "Add 2018-12-27-man-ed-currentstatus.md"},
                "content" => %{
                  "_links" => %{
                    "html" =>
                      "https://github.com/" <>
                        @username <>
                        "/" <> @repository <> "/blob/master/2018-12-27-man-ed-currentstatus.md"
                  }
                }
              }, _} = response

      assert FakeGithub.Contents.files() == ["$ man ed\n\n#currentstatus\n"]
    end

    test "posts a reply to a Github repository" do
      Dolphin.Update.Github.post(%Dolphin.Update{
        text:
        "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!",
        in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
      })

      assert FakeGithub.Contents.files() == [
               "---\nin_reply_to: https://mastodon.social/web/statuses/101195085216392589\n---\n@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!\n"
             ]
    end
  end
end
