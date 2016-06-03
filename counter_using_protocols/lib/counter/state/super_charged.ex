defmodule Counter.State.SuperCharged do
  defstruct total: 0
end

defimpl Counter.State, for: Counter.State.SuperCharged do
  alias Counter.Command.{Increment, SuperCharge}
  alias Counter.Event.{Incremented, SuperCharged}

  def handle_command(_state, %Increment{amount: amount}) do
    [%Counter.Event.Incremented{amount: amount}, %Incremented{amount: amount}]
  end
  def handle_command(state, %SuperCharge{}) do
    []
  end

  def handle_event(state = %{total: total}, %Incremented{amount: amount}) do
    %{state | total: total + amount}
  end
end
