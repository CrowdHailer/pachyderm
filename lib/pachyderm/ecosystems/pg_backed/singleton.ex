defmodule Pachyderm.Ecosystems.PgBacked.Singleton do
  use GenServer

  alias Pachyderm.Ecosystems.PgBacked

  def child_spec({ecosystem, address}) do
    %{
      id: address,
      start: {__MODULE__, :start_link, [ecosystem, address]},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }
  end

  def start_link(ecosystem, address) do
    GenServer.start_link(__MODULE__, {ecosystem, address}, name: {:via, PgBacked, address})
  end
end
