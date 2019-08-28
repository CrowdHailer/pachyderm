defmodule Pachyderm.MixProject do
  use Mix.Project

  def project do
    [
      app: :pachyderm,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Pachyderm.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:eventstore, "~> 0.17.0"},
      {:jason, "~> 1.1"}
    ]
  end
end
