defmodule RequireHistoryWeb.PageControllerTest do
  use RequireHistoryWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end

  test "does table exist" do

    Ecto.Adapters.SQL.query!(RequireHistory.Repo,
      "SELECT t.table_name
      FROM information_schema.tables t
      WHERE t.table_catalog = format('%I', 'require_history_test')
      AND t.table_schema = 'public'
      AND t.table_name not like 'schema_migrations'
      ")
      |> IO.inspect(label: "===> ")
  end
end
