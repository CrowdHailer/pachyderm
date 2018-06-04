defmodule Pachyderm.TaskSupervisor do
  # NOTE there is no option to use Task.Supervisor, add Task.Supervisor.__using__
  def child_spec(name: name) do
    %{id: __MODULE__, start: {Task.Supervisor, :start_link, [[name: name]]}, type: :supervisor}
  end
end
