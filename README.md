# Jellyfish: Simplifying Hot-Upgrades for Elixir Applications

[![Hex.pm Version](http://img.shields.io/hexpm/v/jellyfish.svg?style=flat)](https://hex.pm/packages/jellyfish)

Jellyfish is a library designed to streamline the management of appup and release files, enabling hot-upgrades for Elixir applications. Born from the integration of concepts and functionalities from three influential repositories, Jellyfish empowers developers with efficient tools for maintaining and deploying their Elixir projects with confidence.

 * [Distillery](https://github.com/bitwalker/distillery) - While currently deprecated, its appup generation remains a valuable asset within Jellyfish, ensuring compatibility and reliability in managing upgrades.
 * [Forecastle](https://github.com/ausimian/forecastle) - Offering robust capabilities for release package management.
 * [Relx](https://github.com/erlware/relx/blob/main/priv/templates/install_upgrade_escript) - Providing crucial insights into storing, unpacking, and executing hot upgrades using release files

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jellyfish` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jellyfish, "~> 0.1.2"}
  ]
end
```

You also need to add the following lines in the mix project
```elixir
  def project do
    [
      ...
      compilers: Mix.compilers() ++ [:gen_appup, :appup],
      releases: [
        your_app_name: [
          steps: [:assemble, &Jellyfish.Releases.Copy.relfile/1, :tar]
        ]
      ],
      ...
    ]
  end
```

Once the mix release file is generated, it will contain all the appup/release files to execute a hot-upgrade or full deployment.

# Relup file

The library focuses on generating appup files and including them in the mix release package. It doesn't create relup files directly. If for any reason you need to change the order of the modules in the appup output, you can untar the release, do the changes in the appup files and tar it again. The relup file is typically created during a hot upgrade with the [Deployex](https://github.com/thiagoesteves/deployex) application.

# Examples

Explore [Deployex](https://github.com/thiagoesteves/deployex), an Elixir application showcasing Jellyfish's capabilities in deployment with hot-upgrades.

# References

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/jellyfish>.