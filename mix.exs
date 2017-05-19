defmodule Sippet.Proxy.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :sippet_proxy,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),

     name: "Sippet Proxy",
     docs: [logo: "logo.png"],

     source_url: "https://github.com/balena/elixir-sippet-proxy",
     description: description(),

     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.detail": :test,
       "coveralls.post": :test,
       "coveralls.html": :test
     ]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:sippet, "~> 0.5.8"},

     # Docs dependencies
     {:ex_doc, "~> 0.14", only: :dev, runtime: false},
     {:inch_ex, "~> 0.5", only: :docs},

     # Test dependencies
     {:mock, "~> 0.2.0", only: :test},
     {:excoveralls, "~> 0.6", only: :test},
     {:credo, "~> 0.7", only: [:dev, :test]},
     {:dialyxir, "~> 0.5", only: [:dev], runtime: false}]
  end

  defp description do
    """
    A simple SIP proxy in Elixir.
    """
  end

  defp package do
    [maintainers: ["Guilherme Balena Versiani"],
     licenses: ["BSD"],
     links: %{"GitHub" => "https://github.com/balena/elixir-sippet-proxy"},
     files: ~w"lib mix.exs README.md LICENSE"]
  end
end
