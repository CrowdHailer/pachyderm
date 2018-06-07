defmodule Pachyderm.Ecosystems.DbCoordinated do
  def participate(:default) do
    # Pulls all the config for defaults
    # Start running at boot time
  end
  def participate(_) do
    raise "Only a single ecosystem can be hosted with DbCoordination"
  end
end
