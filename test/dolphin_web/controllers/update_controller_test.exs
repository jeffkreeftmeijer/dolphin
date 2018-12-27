defmodule DolphinWeb.UpdateControllerTest do
  use DolphinWeb.ConnCase

  describe "new update" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.update_path(conn, :new))
      assert html_response(conn, 200) =~ "New Update"
    end
  end

  describe "create update" do
    test "displays a success message", %{conn: conn} do
      conn = post(conn, Routes.update_path(conn, :create), update: %{})
      assert html_response(conn, 200) =~ "Update posted succesfully."
    end
  end
end
