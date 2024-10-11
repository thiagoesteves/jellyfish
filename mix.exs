defmodule Jellyfish.MixProject do
  use Mix.Project

  @version "0.1.4"

  def project do
    [
      app: :jellyfish,
      version: @version,
      elixir: "~> 1.16",
      name: "Jellyfish",
      source_url: "https://github.com/thiagoesteves/jellyfish",
      homepage_url: "https://github.com/thiagoesteves/jellyfish",
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
      files: [
        "lib",
        "priv",
        "mix.exs",
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md",
        ".formatter.exs"
      ],
      maintainers: ["Thiago Esteves", "Matthew Galvin"],
      licenses: ["MIT"],
      links: %{
        Documentation: "https://hexdocs.pm/jellyfish",
        Changelog: "https://hexdocs.pm/jellyfish/changelog.html",
        GitHub: "https://github.com/thiagoesteves/jellyfish"
      }
    ]
  end

  defp docs do
    [
      main: "Jellyfish",
      source_ref: "v#{@version}",
      extras: ["README.md", "LICENSE.md", "CHANGELOG.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false}
    ]
  end
end
