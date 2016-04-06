defmodule LotteryCorp.Web.PageController do
  use LotteryCorp.Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def open_game(conn, _params) do
    redirect conn, to: "/operations/games/56473829"
  end

  def view_game(conn, %{"id" => id}) do
    render conn, "game.html", id: id
  end
end
