defmodule Pachyderm.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Pachyderm.EntitySupervisor, [name: Pachyderm.EntitySupervisor]},
      {Pachyderm.TaskSupervisor, [name: Pachyderm.TaskSupervisor]}
    ]

    opts = [strategy: :one_for_one, name: Pachyderm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
