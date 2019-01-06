defmodule TdHypermedia.MixProject do
  use Mix.Project

  def project do
    [
      app: :td_hypermedia,
      version: "2.11.0",
      elixir: "~> 1.6",
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
      {:phoenix, "~> 1.3 or ~> 1.4"},
      {:poison, "~> 2.2 or ~> 3.0", optional: true},
      {:gettext, "~> 0.15"},
      {:canada, "~> 1.0.2"}
    ]
  end
end
