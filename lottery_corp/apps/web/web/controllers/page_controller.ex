defmodule LotteryCorp.Web.PageController do
  use LotteryCorp.Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def open_game(conn, _params) do
    {:ok, id} = LotteryCorp.Operations.create_game()
    redirect conn, to: "/operations/games/#{id}"
  end

  def view_game(conn, %{"id" => id}) do
    {:ok, game_state} = LotteryCorp.Operations.get_game(id)
    render conn, "game.html", game_state: game_state
  end

  def add_player(conn, %{"game_id" => id, "player" => player}) do
    {:ok, t} = LotteryCorp.Operations.add_player(id, player)
    redirect conn, to: "/operations/games/#{id}"
  end

  def remove_player(conn, %{"game_id" => id, "player" => player}) do
    {:ok, t} = LotteryCorp.Operations.remove_player(id, player)
    redirect conn, to: "/operations/games/#{id}"
  end

  def pick_winner(conn, %{"game_id" => id}) do
    {:ok, t} = LotteryCorp.Operations.pick_winner(id)
    redirect conn, to: "/operations/games/#{id}"
  end

  def show_log(conn, _params) do
    {:ok, log} = LotteryCorp.Operations.EventStore.log(LotteryCorp.Operations.EventStore)
    IO.inspect(log)
    render conn, "log.html", log: log
  end
end
