defmodule Pachyderm.Ecosystems.PgBacked.PgSession do

  def child_spec([]) do
    %{
      id: __MODULE__,
      start: {Postgrex, :start_link, [[hostname: "localhost", username: "elmer", password: "patchwork", database: "elmer", name: __MODULE__]]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end
end
