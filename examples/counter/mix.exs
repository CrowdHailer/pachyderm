defmodule Counter.MixProject do
  use Mix.Project

  def project do
    [
      app: :counter,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Counter.Application, []}
    ]
  end

  defp deps do
    [
      {:ace, "~> 0.16.4"},
      {:pachyderm, path: "../../"}
    ]
  end
end
