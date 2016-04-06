defmodule LotteryCorp.Web.PageController do
  use LotteryCorp.Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def open_game(conn, _params) do
    redirect conn, to: "/operations/games/1"
  end

  def view_game(conn, %{"id" => id}) do
    {:ok, game_state} = LotteryCorp.Operations.get_game(id)
    IO.inspect(game_state)
    render conn, "game.html", game_state: game_state
  end
end
