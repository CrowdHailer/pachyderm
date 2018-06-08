defmodule Pachyderm.Entity do
  @type id :: term
  @type message :: term
  @type state :: term
  @callback init(id) :: state()
  @callback activate(message, state) :: state

  defmacro __using__(_opts) do
    quote location: :keep, bind_quoted: [mod: __MODULE__] do
      @behaviour mod
      def init(id) do
        nil
      end

      def activate(_message, _state) do
        raise "attempted to call #{unquote(mod)} but no activate/2 clause was provided"
      end

      defoverridable mod
    end
  end
end
