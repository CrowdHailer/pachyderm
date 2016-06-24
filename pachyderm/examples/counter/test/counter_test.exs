defmodule CounterTest do
  use ExUnit.Case
  doctest Counter

  test "Running Some counters" do
    {:ok, counter1} = Counter.create
    {:ok, _state} = Counter.add_value(counter1, 1)
    {:ok, _state} = Counter.add_value(counter1, 1)
    {:ok, counter2} = Counter.create
    {:ok, _state} = Counter.add_value(counter2, 2)
    {:ok, _state} = Counter.add_value(counter2, 2)
    {:ok, _state} = Counter.add_value(counter1, -1)
    {:ok, _state} = Counter.add_value(counter2, -2)

    # :observer.start
    # :timer.sleep(30_000)

    {:ok, logs} = Pachyderm.Ledger.view_log()
    IO.puts "\n#{f("entity")} #{f("attribute")} #{f("value")} #{f("time")} #{f("set")}"
    IO.puts(logs |> Enum.map(&format_entry/1) |> Enum.join("\n"))
  end


  def format_entry(%{entity: e, attribute: a, value: v, transaction: t, set: s}) do
    "#{f(e)} #{f(a)} #{f(v)} #{f(t)} #{f(s)}"
  end

  def f(i) when is_atom(i) do
    String.ljust(Atom.to_string(i), 20)
  end
  def f(i) when is_binary(i) do
    String.ljust(i, 20)
  end
  def f(i) when is_number(i) do
    String.ljust(Integer.to_string(i), 20)
  end
end
