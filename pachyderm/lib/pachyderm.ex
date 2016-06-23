defmodule Pachyderm do
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
  def create(%{random: random, ledger: ledger}) do
    id = random.generate()
    adjustments = [
      Pachyderm.Adjustment.set_state(id, State.ZeroCoins)
    ]
    {:ok, _} = ledger.record(adjustments, :creation)
    {:ok, id}
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
end
