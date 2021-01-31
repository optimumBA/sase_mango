defmodule SaseMango.MixProject do
  use Mix.Project

  def project do
    [
      app: :sase_mango,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SaseMango.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:csv, "~> 2.4"},
      {:ecto_sql, "~> 3.5"},
      {:elixir_xml_to_map, "~> 2.0"},
      {:finch, "~> 0.6"},
      {:jason, "~> 1.2"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
