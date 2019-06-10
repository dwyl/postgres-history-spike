defmodule RequireHistoryWeb.PageController do
  use RequireHistoryWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
