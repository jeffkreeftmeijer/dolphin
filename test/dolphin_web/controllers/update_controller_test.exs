defmodule DolphinWeb.UpdateControllerTest do
  use DolphinWeb.ConnCase

  describe "new update" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.update_path(conn, :new))
      assert html_response(conn, 200) =~ "New Update"
    end
  end

  describe "preview update" do
    test "renders previews", %{conn: conn} do
      conn =
        post(conn, Routes.update_path(conn, :create),
          preview: "",
          update: %{"text" => "$ man ed\n\n#currentstatus"}
        )

      assert html_response(conn, 200) =~ "$ man ed\n\n#currentstatus"
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
          update: %{text: "$ man ed\n\n#currentstatus", services: ~w(twitter)}
        )

      assert response = html_response(conn, 200)
      assert response =~ "Update posted succesfully"

      [{_filename, content}] = FakeGithub.Contents.files()
      assert content =~ ~r/\$ man ed\n\n#currentstatus\n/

      assert response =~
               "https://github.com/jeffkreeftmeijer/updates/blob/master/2018-12-27-man-ed-currentstatus.md"

      assert response =~ "https://twitter.com/jkreeftmeijer/status/12119"
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
      assert response =~ "Update posted succesfully"

      [{_filename, file}] = FakeGithub.Contents.files()

      assert file =~ ~r/in_reply_to: https:\/\/mastodon.social\/web\/statuses\/101195085216392589/

      assert file =~
               ~r/@judofyr@ruby.social because ed is the standard text editor \(https:\/\/www.gnu.org\/fun\/jokes\/ed-msg.txt\)!\n/

      assert response =~
               "https://github.com/jeffkreeftmeijer/updates/blob/master/2018-12-27-because-ed-is-the-standard.md"
    end

    test "adds uploaded files", %{conn: conn} do
      conn =
        post(conn, Routes.update_path(conn, :create),
          update: %{
            text: "Well, that escalated.",
            media: [%Plug.Upload{path: "test/screenshot.png", filename: "screenshot.png"}]
          }
        )

      assert response = html_response(conn, 200)
      assert response =~ "Update posted succesfully"

      [_, {"media/screenshot.png", _}] = FakeGithub.Contents.files()
    end

    test "selects services to post to", %{conn: conn} do
      conn =
        post(conn, Routes.update_path(conn, :create),
          update: %{text: "$ man ed\n\n#currentstatus", services: ["twitter"]}
        )

      assert response = html_response(conn, 200)

      assert response =~ "twitter.com"
      refute response =~ "mastodon.social"
    end
  end
end
