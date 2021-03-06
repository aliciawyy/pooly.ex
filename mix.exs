defmodule Pooly.MixProject do
  use Mix.Project

  def project do
    [
      app: :pooly,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Pooly, []}
    ]
  end

  defp aliases do
    [
      test: "test --no-start --cover"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlex, "~> 0.1", only: [:dev]},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
