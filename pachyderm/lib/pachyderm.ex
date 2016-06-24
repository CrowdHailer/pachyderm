defmodule Pachyderm do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      worker(Pachyderm.Ledger.InMemory, [[name: Pachyderm.Ledger]]),
      worker(Pachyderm.Entity.Supervisor, [[name: Pachyderm.Entity.Supervisor]]),
    ]

    opts = [strategy: :one_for_one, name: Pachyderm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

  def generate_id do
    random_string(10)
  end
end
defmodule VendingMachine do
  defmodule Command do
    defmodule AddCoin, do: defstruct []
    defmodule PushButton, do: defstruct []
  end
  defmodule State do
    defmodule ZeroCoins do
      defstruct [id: nil]
    end
    defmodule OneCoin do
      defstruct [id: nil]
    end
    defmodule TwoCoins do
      defstruct [id: nil]
    end
  end
  def create() do
    id = Pachyderm.generate_id
    {:ok, adjustments} = creation(id)
    {:ok, _transaction} = Pachyderm.Ledger.record(Pachyderm.Ledger, adjustments, :creation)
    {:ok, id}
  end
  def create(%{random: random, ledger: ledger}) do
    id = random.generate()
    adjustments = [
      Pachyderm.Adjustment.set_state(id, State.ZeroCoins)
    ]
    {:ok, _} = ledger.record(adjustments, :creation)
    {:ok, id}
  end

  def creation(id) do
    {:ok, [Pachyderm.Adjustment.set_state(id, State.ZeroCoins)]}
  end

  def add_coin(id) do
    Pachyderm.Entity.instruct(id, %VendingMachine.Command.AddCoin{})
  end
end
defimpl Pachyderm.Protocol, for: VendingMachine.State.ZeroCoins do
  def instruct(%{id: id}, %VendingMachine.Command.AddCoin{}) do
    {:ok, [
      Pachyderm.Adjustment.unset_state(id, VendingMachine.State.ZeroCoins),
      Pachyderm.Adjustment.set_state(id, VendingMachine.State.OneCoin)
    ]}
  end
end
defimpl Pachyderm.Protocol, for: VendingMachine.State.OneCoin do
  def instruct(%{id: id}, %VendingMachine.Command.AddCoin{}) do
    {:ok, [
      Pachyderm.Adjustment.unset_state(id, VendingMachine.State.OneCoin),
      Pachyderm.Adjustment.set_state(id, VendingMachine.State.TwoCoins)
    ]}
  end
end
defimpl Pachyderm.Protocol, for: VendingMachine.State.TwoCoins do
  def instruct(%{id: id}, %VendingMachine.Command.PushButton{}) do
    {:ok, [
      Pachyderm.Adjustment.unset_state(id, VendingMachine.State.TwoCoins),
      Pachyderm.Adjustment.set_state(id, VendingMachine.State.OneCoin)
    ]}
  end
  def instruct(_state, command) do
    {:error, {:unknown_command, command}}
  end
end
