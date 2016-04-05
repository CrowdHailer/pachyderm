defmodule LotteryCorp.Web.PageController do
  use LotteryCorp.Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
