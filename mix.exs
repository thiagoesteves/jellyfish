defmodule Jellyfish.MixProject do
  use Mix.Project

  def project do
    [
      app: :jellyfish,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp description do
    """
    Build appup files for your Elixir app release
    """
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md", ".formatter.exs"],
      maintainers: ["Paul Schoenfelder"],
      licenses: ["MIT"],
      links: %{
        Documentation: "https://hexdocs.pm/distillery",
        Changelog: "https://hexdocs.pm/distillery/changelog.html",
        GitHub: "https://github.com/bitwalker/distillery"
      }
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/thiagoesteves/jellyfish",
      homepage_url: "https://github.com/thiagoesteves/jellyfish",
      main: "home"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
