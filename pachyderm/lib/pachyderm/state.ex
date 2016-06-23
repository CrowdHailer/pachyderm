defmodule Pachyderm.State do
  def react(state, %{adjustments: adjustments}) do
    Enum.reduce(adjustments, state, fn(a, s) -> adjust(s, a) end)
  end

  def adjust(state = %{id: id}, adjustment = %{entity: id}) do
    do_adjust(state, adjustment)
  end
  def adjust(state, _adjustment) do
    state
  end

  defp do_adjust(state, %{attribute: attribute, value: value, set: true}) do
    set_attribute(state, attribute, value)
  end
  defp do_adjust(state, %{attribute: attribute, value: value, set: false}) do
    unset_attribute(state, attribute, value)
  end

  defp set_attribute(state, :__struct__, value) do
    state = Map.delete(state, :__struct__)
    struct(value, state)
  end
  defp set_attribute(state, attribute, value) do
    Map.put(state, attribute, value)
  end
  defp unset_attribute(state, attribute, value) do
    Map.put(state, attribute, nil)
  end
end
