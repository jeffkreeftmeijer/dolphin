defmodule DolphinWeb.UpdateControllerTest do
  use DolphinWeb.ConnCase

  describe "new update" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.update_path(conn, :new))
      assert html_response(conn, 200) =~ "New Update"
    end
  end

  describe "create update" do
    test "displays the URLs the update has been posted to", %{conn: conn} do
      conn =
        post(conn, Routes.update_path(conn, :create),
          update: %{text: "$ man ed\n\n#currentstatus"}
        )

      assert response = html_response(conn, 200)
      assert response =~ "Update posted succesfully."

      assert response =~
               "https://github.com/jeffkreeftmeijer/testing/blob/master/2018-12-27-man-ed-currentstatus.md"
    end
  end
end
