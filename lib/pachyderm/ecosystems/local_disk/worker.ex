defmodule Pachyderm.Ecosystems.LocalDisk.Worker do
  use GenServer

  @enforce_keys [:address, :ecosystem, :entity_state]
  defstruct @enforce_keys

  def child_spec({ecosystem, address}) do
    %{
      id: address,
      start:
        {__MODULE__, :start_link,
         [ecosystem, address]},
      type: :worker,
      restart: :temporary,
      shutdown: 500
    }
  end


  def start_link(ecosystem, address) do
    GenServer.start_link(__MODULE__, {ecosystem, address})
  end
  def init({ecosystem, address}) do
    {ref, _pid} = ecosystem
    :ok = :pg2.create({ref, address})

    {kind, entity_id} = address
    # use :some/:none because state can be nil
    entity_state = case get_entity_state(ecosystem, address) do
      :none ->
        entity_state = kind.init(entity_id)
        :ok = save_entity_state(ecosystem, address, entity_state)
        entity_state
      {:some, entity_state} ->
        entity_state
    end
    # NOTE maybe this step should return ok error and handle typing for addresses
    {:ok, %__MODULE__{address: address, ecosystem: ecosystem, entity_state: entity_state}}
  end

  def handle_call({:send, :kill}, _from, state) do
    {:reply, :ok, state, 0}
  end
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
  def handle_call({:send, message}, _from, state) do
    {kind, entity_id} = state.address
    {ref, _} = state.ecosystem
    {envelopes, entity_state} = kind.activate(message, state.entity_state)
    :ok = save_entity_state(state.ecosystem, state.address, entity_state)
    state = %{state | entity_state: entity_state}
    for follower <- :pg2.get_members({ref, state.address}) do
      send(follower, {state.address, entity_state})
    end
    # TODO cast follow on messages,
    # Just say guarantees are at most once.
    # TODO add definition of ecosystem in readme, update docs with this environment
    # remove this part from the ROADMAP
    # TODO also comment this is as slow as possible to get the consistency of write
    # I suspect it should only be used for core things
    {:reply, {:ok, state.entity_state}, state}
  end
  def handle_call({:follow, follower}, _from, state) do
    {ref, _pid} = state.ecosystem
    :ok = :pg2.join({ref, state.address}, follower)
    {:reply, {:ok, state.entity_state}, state}
  end

  # Can insert a list of messges with dets,
  def save_entity_state({ref, _}, address, state) do
    {:ok, :pachyderm} = :dets.open_file(:pachyderm, [file: 'pachyderm.ets', type: :set])
    result = :dets.insert(:pachyderm, {{ref, address}, state})
    :ok = :dets.close(:pachyderm)
    result
  end

  def get_entity_state({ref, _}, address) do
    {:ok, :pachyderm} = :dets.open_file(:pachyderm, [file: 'pachyderm.ets', type: :set])
    IO.inspect("loading")
    result = case :dets.lookup(:pachyderm, {ref, address}) do
      [] ->
        :none
      [{_, state}] ->
        {:some, state}
    end
    |> IO.inspect
    IO.inspect("-----")
    :ok = :dets.close(:pachyderm)
    result
  end
end
