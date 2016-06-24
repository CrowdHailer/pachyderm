defmodule Pachyderm.Entity do
  alias Pachyderm.{Ledger, Protocol, State}

  use GenServer

  def start_link(id, ledger \\ Pachyderm.Ledger) do
    GenServer.start_link(__MODULE__, {id, ledger}, name: via_tuple(id))
  end

  defp via_tuple(id) do
    {:via, :gproc, {:n, :l, {__MODULE__, id}}}
  end

  def instruct(entity, instruction) when is_pid(entity)  do
    GenServer.call(entity, {:instruction, instruction})
  end
  def instruct(entity, instruction)  do
    case Pachyderm.Entity.Supervisor.start_child(Pachyderm.Entity.Supervisor, [entity]) do
      {:ok, _pid} ->
        GenServer.call(via_tuple(entity), {:instruction, instruction})
      {:error, {:already_started, _pid}} ->
        GenServer.call(via_tuple(entity), {:instruction, instruction})
      other ->
        other
    end
  end
  def init({id, ledger}) do
    case Ledger.InMemory.inspect(ledger, self) do
      {:ok, 0} ->
        {:stop, :no_records}
      {:ok, count} ->
        logs = read_logs(count, [])
        empty_state = %{id: id}
        state = State.react(empty_state, %{adjustments: logs})
        case empty_state == state do
          true -> {:stop, {:unknown_entity, id}}
          false ->
            {:ok, {state, ledger}}
        end
    end
  end
  defp read_logs(t, total) do
    receive do
      {_, %{adjustments: adjusments, id: id}} ->
        case id == t do
          true -> total ++ adjusments
          false -> read_logs(t, total ++ adjusments)
        end
      end
    end

  def handle_call({:instruction, instruction}, _from, {state, ledger}) do
    case Protocol.instruct(state, instruction) do
      {:ok, adjustments} ->
        {:ok, reaction = %{id: id}} = Ledger.InMemory.record(ledger, adjustments, instruction)
        receive do
          {:"$LedgerEntry", %{id: ^id}} ->
        end
        state = State.react(state, reaction)
        {:reply, {:ok, state}, {state, ledger}}
      {:error, reason} ->
        {:reply, {:error, reason}, {state, ledger}}
    end
  end

  def handle_info({:"$LedgerEntry", reaction}, {state, ledger}) do
    state = State.react(state, reaction)
    {:noreply, {state, ledger}}
  end
end
