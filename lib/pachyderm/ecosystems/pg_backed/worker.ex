defmodule Pachyderm.Ecosystems.PgBacked.Worker do
  use GenServer

  alias Pachyderm.Ecosystems.PgBacked

  def child_spec({address, ecosystem}) do
    %{
      id: address,
      start: {__MODULE__, :start_link, [address, ecosystem]},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }
  end

  def start_link(address, ecosystem) do
    GenServer.start_link(
      __MODULE__,
      {address, ecosystem},
      name: PgBacked.via_tuple(address, ecosystem))
  end

  def init({address, ecosystem}) do
    {:ok, {address, ecosystem}}
  end

  def handle_call(a, from, state) do
    {:reply, :ok, state}
  end
end
