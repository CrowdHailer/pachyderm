defmodule LotteryCorp.Operations.Game.State do
  defstruct winner: :none, players: [], uuid: :none

  def init(game_id) do
    %__MODULE__{uuid: game_id}
  end

  def issue_command({:add_player, player}, %{players: players, winner: :none}) do
    case Enum.member?(players, player) do
      true -> {:ok, :no_change}
      false -> {:ok, {:added_player, player}}
    end
  end
  def issue_command({:remove_player, player}, %{players: players, winner: :none}) do
    case Enum.member?(players, player) do
      true -> {:ok, {:removed_player, player}}
      false -> {:ok, :no_change}
    end
  end
  def issue_command({:pick_winner, _seed}, %{players: []}) do
    {:error, :no_players_to_win}
  end
  def issue_command({:pick_winner, _seed}, %{players: players, winner: :none}) do
    winner = Enum.random(players)
    {:ok, {:picked_winner, winner}}
  end
  def issue_command(_command, %{winner: _winner}) do
    {:error, :lottery_closed}
  end

  def apply_event({:added_player, player}, state = %{players: players}) do
    %{state | players: players ++ [player]}
  end
  def apply_event({:removed_player, player}, state = %{players: players}) do
    %{state | players: Enum.filter(players, fn(p) -> p != player end)}
  end
  def apply_event({:picked_winner, winner}, state = %{winner: :none}) do
    %{state | winner: winner}
  end
  def apply_event(:no_change, state) do
    state
  end
end
