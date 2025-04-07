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
    {:jellyfish, "~> 0.2.0"}
  ]
end
```

You also need to add the following line in the mix project
```elixir
  def project do
    [
      ...
      releases: [
        your_app_name: [
          steps: [:assemble, &Jellyfish.Releases.Generate.appup_files/1, :tar]
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

The library focuses on generating appup files and includes them in the mix release package. It doesn't create relup files directly. The relup file is typically created during a hot upgrade with the [DeployEx](https://github.com/thiagoesteves/deployex) application.

# Elixir Umbrella applications

The next sections describe how to set up and use Jellyfish with Elixir umbrella applications for hot code upgrades.

## Versioning

Elixir umbrella applications contain multiple apps with multiple `mix.exs` files and versions. Jellyfish expects a single version for the entire umbrella application, so it's important to ensure the same version is used across all apps. The recommended approach is to use a `version.txt` file at the root of your umbrella project.

Root Mix File Setup:
```Elixir
defmodule Myumbrella.MixProject do
  use Mix.Project

  @version File.read!("version.txt")

  def project do
    [
      apps_path: "apps",
      version: @version,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        myumbrella: [
          applications: [
            app_1: :permanent,
            app_2: :permanent,
            app_web: :permanent
          ],
          steps: [
            :assemble,
            &Jellyfish.Releases.Generate.appup_files/1,
            :tar
          ]
        ]
      ]
    ]

      defp deps do
    [
      {:jellyfish, "~> 0.2.0"}
    ]
  end
end
```

Each application within the umbrella should reference the same version file:

> #### Child App Mix File Setup
>
> Jellyfish dependency is not required for the child apps

```Elixir
defmodule App1.MixProject do
  use Mix.Project

  @version File.read!("../../version.txt")

  def project do
    [
      app: :app_1,
      version: @version,
      # Other configuration...
    ]
  end
  # Rest of the mix file...
end
```

## Generating Appup files

When building releases for hot code upgrades in umbrella applications, there's a known issue where the first release call after a version change doesn't properly update all the applications within the umbrella. This can result in missing files. For proper appup file generation, follow these steps:

1. Build the initial release:
```bash
# Release the version 0.1.0
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
```

2. Update the version (e.g., from `0.1.0` to `0.1.1`) in `version.txt`
3. Build the new release with forced compilation:
```bash
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix compile --force
MIX_ENV=prod mix release
```

# Examples
Explore these resources for practical examples of using Jellyfish with Elixir applications:

 * [Deployex](https://github.com/thiagoesteves/deployex) - Elixir application showcasing Jellyfish's capabilities in deployment with hot-upgrades.
 * [Calori](https://github.com/thiagoesteves/calori) - Elixir application using Jellyfish and being able to hot upgrade via DeployEx
 * [Myumbrella](https://github.com/thiagoesteves/myumbrella) - Elixir umbrella application configured for using Jellyfish.

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