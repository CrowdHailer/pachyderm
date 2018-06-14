defmodule Pachyderm.Ecosystems.PgBacked.Supervisor do
  use Supervisor

  alias Pachyderm.Ecosystems.PgBacked

  # take a config map with db name ecosystem_id
  def start_link(ecosystem_id) do
    Supervisor.start_link(__MODULE__, ecosystem_id)
  end

  @impl Supervisor
  def init(ecosystem_id) do
    children = [
      PgBacked.PgSession,
      {PgBacked.Registry, ecosystem_id},
      PgBacked.WorkerSupervisor,
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def registry(supervisor) do
    Supervisor.which_children(supervisor)
    |> Enum.find(fn({k, _, _, _}) -> k == PgBacked.Registry end)
    |> elem(1)
  end

  def pg_session(supervisor) do
    Supervisor.which_children(supervisor)
    |> Enum.find(fn({k, _, _, _}) -> k == PgBacked.PgSession end)
    |> elem(1)
  end

  def worker_supervisor(supervisor) do
    Supervisor.which_children(supervisor)
    |> Enum.find(fn({k, _, _, _}) -> k == PgBacked.WorkerSupervisor end)
    |> elem(1)
  end
end
