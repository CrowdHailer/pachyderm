defmodule Counter.State.Normal do
  defstruct total: 0
end

defimpl Counter.State, for: Counter.State.Normal do
  alias Counter.Command.{Increment, SuperCharge}
  alias Counter.Event.{Incremented, SuperCharged}

  def handle_command(_state, %Increment{amount: amount}) do
    [%Counter.Event.Incremented{amount: amount}]
  end
  def handle_command(_state, %SuperCharge{}) do
    [%Counter.Event.SuperCharged{}]
  end

  def handle_event(state = %{total: total}, %Incremented{amount: amount}) do
    %{state | total: total + amount}
  end
  def handle_event(state, %SuperCharged{}) do
    %{state | :__struct__ => Counter.State.SuperCharged}
  end
end
