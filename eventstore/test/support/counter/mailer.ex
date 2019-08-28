defmodule Counter.Mailer do
  @behaviour Pachyderm.Effect

  @impl Pachyderm.Effect
  def dispatch(message, %{mailer: %{test: pid}}) do
    send(pid, message)
    :ok
  end
end
