defmodule Counter.WWW do
  use Ace.HTTP.Service, port: 8080, cleartext: true

  # use Pachyderm.Web, {"counter", Counter}

  def handle_request(request = %{path: [type, id | _rest]}, %{}) do
    Pachyderm.execute(entity(type), id, request)
  end

  def entity("counter") do
    Counter
  end

  def context(_config) do
    # Pachyderm.global() -> will start the application
  end
end
