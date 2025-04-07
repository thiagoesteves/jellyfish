defmodule Jellyfish.MixProject do
  use Mix.Project

  @version "0.2.1"

  def project do
    [
      app: :jellyfish,
      version: @version,
      elixir: "~> 1.16",
      name: "Jellyfish",
      description: "Elixir library able to generate appup files for hot code reloading",
      source_url: "https://github.com/thiagoesteves/jellyfish",
      homepage_url: "https://github.com/thiagoesteves/jellyfish",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
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

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      release: [
        "cmd git tag v#{@version} -f",
        "cmd git push",
        "cmd git push --tags",
        "hex.publish --yes"
      ],
      "test.ci": [
        "format --check-formatted",
        "deps.unlock --check-unused"
      ]
    ]
  end
end
