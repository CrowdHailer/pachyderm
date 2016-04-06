defmodule LotteryCorp.Operations.Game.Registry do
  use GenServer

  def start_link(supervisor) do
    # Can pass event store as pid because if fails they are all restarted together by top level supervisor
    GenServer.start_link(__MODULE__, supervisor, [name: __MODULE__])
  end

  def lookup(registry, id) do
    # FIXME to test registry we need to not clash on global.
    # OR just create random buckets so don't clash
    case :global.whereis_name({__MODULE__, id}) do
      :undefined ->
        GenServer.call(registry, {:create, id})
      pid ->
        {:ok, pid}
    end
  end

  def handle_call({:create, id}, _from, supervisor) do
    game = case :global.whereis_name({__MODULE__, id}) do
      :undefined ->
        {:ok, game} = LotteryCorp.Operations.Game.Supervisor.start_game(supervisor, id)
        :global.register_name({__MODULE__, id}, game)
        game
      pid ->
        pid
   end
    {:reply, {:ok, game}, supervisor}
  end
end
