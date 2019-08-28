defmodule Pachyderm.MixProject do
  use Mix.Project

  def project do
    [
      app: :pachyderm,
      version: "0.2.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: [extras: ["README.md"], main: "readme", assets: ["assets"]],
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Pachyderm.Application, []}
    ]
  end

  defp description do
    """
    Virtual actor framework, giving you globally unique durable entities.
    """
  end

  defp package do
    [
      maintainers: ["Peter Saxton"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/crowdhailer/raxx"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:eventstore, "~> 0.17.0"},
      {:jason, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
