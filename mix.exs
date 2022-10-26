defmodule TdHypermedia.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_hypermedia,
      version: "4.54.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.6.0"},
      {:gettext, "~> 0.20"},
      {:canada, "~> 2.0.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end
