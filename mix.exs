defmodule Pachyderm.MixProject do
  use Mix.Project

  def project do
    [
      app: :pachyderm,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: [extras: ["README.md"], main: "readme"],
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Pachyderm.Application, []}
    ]
  end

  defp deps do
    [
      {:postgrex, "~> 0.13.5"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Immortal(virtual) actors.
    """
  end

  defp package do
    [
      maintainers: ["Peter Saxton"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/crowdhailer/pachyderm"}
    ]
  end
end
