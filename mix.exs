defmodule Refraner.Mixfile do
  use Mix.Project

  def project do
    [
      app: :refraner,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Refraner.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 0.13"},
      {:floki, "~> 0.18.0"},
      {:ecto, "~> 2.0"},
      {:mariaex, "~> 0.8.2"}
    ]
  end
end
