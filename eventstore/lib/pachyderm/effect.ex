defmodule Pachyderm.Effect do
  @callback dispatch(module, term) :: :ok

  @doc false
  def dispatch_all(effects, config) do
    for {module, message} <- effects do
      :ok = module.dispatch(message, config)
    end

    :ok
  end
end
