# Jellyfish

> Simplifying Hot-Upgrades for Elixir Applications

[![Hex.pm Version](http://img.shields.io/hexpm/v/jellyfish.svg?style=flat)](https://hex.pm/packages/jellyfish)

Jellyfish is a library designed to streamline the management of appup and release files, enabling hot-upgrades for Elixir applications. Born from the integration of concepts and functionalities from three influential repositories:

 * [Distillery](https://github.com/bitwalker/distillery)
 * [Forecastle](https://github.com/ausimian/forecastle)
 * [Relx](https://github.com/erlware/relx/blob/main/priv/templates/install_upgrade_escript)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jellyfish` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jellyfish, "~> 0.1.4"}
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

Once the mix release file is generated, it will contain all the appup file to execute a hot-upgrade or full deployment.

# Appup file

If for any reason you need to change the order of the modules or add new commands in the appup file, you have 2 options:

 1. Use the __EDIT_APPUP__ environment variable to indicate to Jellifish that you want to edit the file before the release:
```bash
EDIT_APPUP=true MIX_ENV=prod mix release
```

 2. Untar the release, do the changes in the appup files and tar it again.

# Relup file

The library focuses on generating appup files and includes them in the mix release package. It doesn't create relup files directly. The relup file is typically created during a hot upgrade with the [Deployex](https://github.com/thiagoesteves/deployex) application.

# Examples

Explore [Deployex](https://github.com/thiagoesteves/deployex), an Elixir application showcasing Jellyfish's capabilities in deployment with hot-upgrades.

## Getting involved

🗨️ **Contact us:**
Feel free to contact me on [Linkedin](https://www.linkedin.com/in/thiago-cesar-calori-esteves-972368115/).

## Copyright and License

Copyright (c) 2024, Thiago Esteves.

DeployEx source code is licensed under the [MIT License](LICENSE.md).

# References

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/jellyfish>.