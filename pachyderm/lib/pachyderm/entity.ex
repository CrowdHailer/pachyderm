defmodule Pachyderm.Entity do
  alias Pachyderm.{Ledger, Protocol, State}

  use GenServer

  def start_link(id, ledger) do
    GenServer.start_link(__MODULE__, {id, ledger})
  end

  def instruct(entity, instruction) do
    GenServer.call(entity, {:instruction, instruction})
  end
  def init({id, ledger}) do
    case Ledger.InMemory.inspect(ledger, self) do
      # {:ok, 0} ->
      #   {:ok, {%Counter.State.Normal{}, ledger}}
      {:ok, count} ->
        # propably should handle catchup in a special manner
        {:ok, {%{id: id}, ledger}}
    end
  end

  def handle_call({:instruction, instruction}, _from, {state, ledger}) do
    {:ok, adjustments} = Protocol.instruct(state, instruction)
    {:ok, reaction = %{id: id}} = Ledger.InMemory.record(ledger, adjustments, instruction)
    receive do
      {:"$LedgerEntry", %{id: ^id}} ->
    end
    state = State.react(state, reaction)
    {:reply, {:ok, state}, {state, ledger}}
  end

  def handle_info({:"$LedgerEntry", reaction}, {state, ledger}) do
    state = State.react(state, reaction)
    {:noreply, {state, ledger}}
  end
end
