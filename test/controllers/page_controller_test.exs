defmodule FeedlexDemo.PageControllerTest do
  use FeedlexDemo.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Feedly"
  end
end
