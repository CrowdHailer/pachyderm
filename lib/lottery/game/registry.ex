defmodule Lottery.Game.Registry do
  use GenServer

  def start_link do
    # Can pass event store as pid because if fails they are all restarted together by top level supervisor
    GenServer.start_link(__MODULE__, :supervisor, [name: __MODULE__])
  end
end
