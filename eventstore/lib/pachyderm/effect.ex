defmodule Pachyderm.Effect do
  @callback dispatch(module, term) :: :ok
end
