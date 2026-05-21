defmodule TdHypermedia.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_hypermedia,
      version: "8.6.1",
      elixir: "~> 1.18",
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
      {:plug, "~> 1.19.2"},
      {:phoenix, "~> 1.7.18"},
      {:phoenix_view, "~> 2.0"},
      {:gettext, "~> 0.26.2"},
      {:canada, "~> 2.0.0"},
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false}
    ]
  end
end
