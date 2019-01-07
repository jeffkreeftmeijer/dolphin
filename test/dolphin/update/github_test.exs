defmodule Dolphin.Update.GithubTest do
  use ExUnit.Case, async: true
  doctest Dolphin.Update.Github
  alias Dolphin.{Update, Update.Github}

  @credentials Application.get_env(:dolphin, :github_credentials)
  @username @credentials[:username]
  @repository @credentials[:repository]

  setup do
    FakeGithub.Contents.start_link()
    :ok
  end

  describe "from_update/1" do
    test "creates a Github update from an Update" do
      assert Github.from_update(%Update{
               text: "$ man ed\n\n#currentstatus"
             }) ==
               %Github{
                 filename: "2018-12-27-man-ed-currentstatus.md",
                 content: "$ man ed\n\n#currentstatus\n"
               }
    end

    test "removes carriage returns from update texts" do
      %Github{content: content} =
        %Update{text: "$ man ed\r\n\r\n#currentstatus"}
        |> Github.from_update()

      refute String.contains?(content, "\r")
    end

    test "creates a Github reply from an Update" do
      assert Github.from_update(%Update{
               text:
                 "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!",
               in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
             }) ==
               %Github{
                 filename: "2018-12-27-because-ed-is-the-standard.md",
                 content: """
                 ---
                 in_reply_to: https://mastodon.social/web/statuses/101195085216392589
                 ---
                 @judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!
                 """
               }
    end

    test "creates a Github update with media an Update" do
      assert %Github{
               content: "Well, that escalated.\n",
               media: [%Plug.Upload{path: "test/screenshot.png", filename: "screenshot.png"}]
             } =
               Github.from_update(%Update{
                 text: "Well, that escalated.",
                 media: [%Plug.Upload{path: "test/screenshot.png", filename: "screenshot.png"}]
               })
    end
  end

  describe "post/1" do
    test "posts a file to a Github repository" do
      update = %Github{
        content: "$ man ed\n\n#currentstatus\n",
        filename: "2018-12-27-man-ed-currentstatus.md"
      }

      expected_url =
        "https://github.com/#{@username}/#{@repository}/blob/master/2018-12-27-man-ed-currentstatus.md"

      assert Github.post(update) == {:ok, [expected_url]}

      assert FakeGithub.Contents.files() == [
               {"2018-12-27-man-ed-currentstatus.md", "$ man ed\n\n#currentstatus\n"}
             ]
    end

    test "uploads media attachments to Github" do
      upload = %Plug.Upload{
        content_type: "image/jpeg",
        filename: "screenshot.png",
        path: "test/screenshot.png"
      }

      Github.post(%Github{
        content: "![Screenshot](/media/file.jpg)",
        filename: "2018-12-27-screenshot.png",
        media: [upload]
      })

      upload_contents = File.read!("test/screenshot.png")

      assert [{_filename, _content}, {"media/screenshot.png", ^upload_contents}] =
               FakeGithub.Contents.files()
    end
  end

  describe "get_metadata/2" do
    test "finds the syndication URL for an update" do
      assert Github.get_metadata(
               "2018-12-20-you-mean-setting-macros-with.md",
               "in_reply_to"
             ) == {:ok, "https://ruby.social/@solnic/101275229051824324"}
    end
  end
end
