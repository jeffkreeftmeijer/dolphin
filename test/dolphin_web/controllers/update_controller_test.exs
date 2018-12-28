defmodule DolphinWeb.UpdateControllerTest do
  use DolphinWeb.ConnCase

  describe "new update" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.update_path(conn, :new))
      assert html_response(conn, 200) =~ "New Update"
    end
  end

  describe "create update" do
    setup do
      FakeGithub.Contents.start_link()
      :ok
    end

    test "displays the URLs the update has been posted to", %{conn: conn} do
      conn =
        post(conn, Routes.update_path(conn, :create),
          update: %{text: "$ man ed\n\n#currentstatus"}
        )

      assert response = html_response(conn, 200)
      assert response =~ "Update posted succesfully."

      assert FakeGithub.Contents.files() == ["$ man ed\n\n#currentstatus\n"]

      assert response =~
               "https://github.com/jeffkreeftmeijer/testing/blob/master/2018-12-27-man-ed-currentstatus.md"
    end

    test "adds front matter to posted updates for replies", %{conn: conn} do
      conn =
        post(conn, Routes.update_path(conn, :create),
          update: %{
            text:
              "@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!",
            in_reply_to: "https://mastodon.social/web/statuses/101195085216392589"
          }
        )

      assert response = html_response(conn, 200)
      assert response =~ "Update posted succesfully."

      assert FakeGithub.Contents.files() == [
               "---\nin_reply_to: https://mastodon.social/web/statuses/101195085216392589\n---\n@judofyr@ruby.social because ed is the standard text editor (https://www.gnu.org/fun/jokes/ed-msg.txt)!\n"
             ]

      assert response =~
               "https://github.com/jeffkreeftmeijer/testing/blob/master/2018-12-27-because-ed-is-the-standard.md"
    end
  end
end
