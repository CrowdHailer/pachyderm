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
    IO.inspect(address)
    IO.inspect(ecosystem)
    GenServer.start_link(
      __MODULE__,
      {address, ecosystem},
      name: {:via, PgBacked.Registry, {address, ecosystem}})
    |> IO.inspect
  end

  def init({address, ecosystem}) do
    IO.inspect("Started")
    IO.inspect(self)
    {:ok, {address, ecosystem}}
  end

  def handle_call(a, from, state) do
    IO.inspect(a)
    IO.inspect(self)
    {:reply, :ok, state}
  end
end
