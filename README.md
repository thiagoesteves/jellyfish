# Jellyfish

> Simplifying Hot-Upgrades for Elixir Applications

[![Hex.pm Version](http://img.shields.io/hexpm/v/jellyfish.svg?style=flat)](https://hex.pm/packages/jellyfish)

Jellyfish is a library that generates appup files, enabling hot-upgrades for Elixir applications without downtime.

## What are Appup Files?
Appup files describe how to upgrade and downgrade an application from one version to another. They contain:

 * The application name
 * Instructions to upgrade to a newer version
 * Instructions to downgrade to the original version

For detailed information about the appup format, see the [Erlang appup manual](http://erlang.org/doc/man/appup.html).

## Important Upgrade Ordering
When upgrading processes, order matters:

 * Processes are suspended during upgrades
 * In-flight requests are handled by the old version until upgrade completes
 * Upgrade dependencies first, then dependents (e.g., if `proc_a` depends on `proc_b`, upgrade `proc_b` first)
 * Jellyfish automatically performs topological sorting when generating appups

References:

 * [Distillery](https://github.com/bitwalker/distillery)
 * [Forecastle](https://github.com/ausimian/forecastle)
 * [Relx](https://github.com/erlware/relx/blob/main/priv/templates/install_upgrade_escript)

## Installation

Add `jellyfish` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jellyfish, "~> 0.2.0"}
  ]
end
```

## Basic Configuration
Add the following lines in the `mix.exs` project:

```elixir
  def project do
    [
      ...
      releases: [
        your_app_name: [
          steps: [:assemble, &Jellyfish.generate/1, :tar]
        ]
      ],
      ...
    ]
  end
```

Once the `mix release` is called, if a previous version is found, the appup file will be automatically generated and included in the release package for executing hot-upgrades.

### Hot-Upgrading Dependencies (Optional)

By default, Jellyfish generates appup files only for your application code. To include specific libraries in hot-upgrades, add them to the `hot_upgrade_deps` list.

> [!WARNING]
> Before adding a library to the hot-upgrade list, verify that its version update supports hot-upgrades. Not all libraries (and all versions) are designed to be safely upgraded at runtime.

#### Standard Elixir projects
```elixir
  def project do
    [
      ...
      releases: [
        your_app_name: [
          ...
          steps: [:assemble, &Jellyfish.generate/1, :tar]
        ]
      ],
      hot_upgrade_deps: [:any_library],
      ...
    ]
  end
```

#### Umbrella projects
```elixir
  def project do
    [
      ...
      releases: [
        your_app_name: [
          ...
          steps: [:assemble, &Jellyfish.generate/1, :tar],
          applications: [
            app_1: :permanent,
            app_2: :permanent,
            app_3: :permanent,
            app_web: :permanent
          ],
        ]
      ],
      hot_upgrade_deps: [:any_library],
      ...
    ]
  end
```

Jellyfish will search for and create appup files for both your applications and the specified dependencies.

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

Elixir umbrella applications contain multiple apps, each with its own `mix.exs` file and version. However, Jellyfish expects a single consistent version for the entire umbrella application. To ensure version consistency across all apps, we recommend two approaches:"

### Versioning using a shared mix config

Create a new file `mix/shared.exs` at the root of your umbrella project and add the following code:
```Elixir
defmodule Mix.Shared do
  def version, do: "0.1.0"
end
```

Add the load of this file in the root Mix File Setup:
```Elixir
Code.require_file("mix/shared.exs")

defmodule Myumbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: Mix.Shared.version(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        myumbrella: [
          applications: [
            app_1: :permanent,
            app_2: :permanent,
            app_web: :permanent
          ],
          steps: [:assemble, &Jellyfish.generate/1, :tar]
        ]
      ],
      hot_upgrade_deps: [:any_library], # Optional
      ...
    ]
  end

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

  def project do
    [
      app: :app_1,
      version: Mix.Shared.version(),
      # Other configuration...
    ]
  end
  # Rest of the mix file...
end
```

### Versioning using a text file
Create a new file `version.txt` at the root of your umbrella project.

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
          steps: [:assemble, &Jellyfish.generate/1, :tar]
        ]
      ]
    ]
  end

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

When building releases for hot code upgrades in umbrella applications, modifying the version file does not trigger the compiler to detect changes in mix.exs across all apps. In this scenario, all apps need to be recompiled to make the new version available to the compiler's tasks, which would normally require forcing compilation.

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

**Why --force is needed**: Modifying the version file alone doesn't trigger the compiler to detect changes across all umbrella apps. Forcing compilation ensures the new version is available to all compiler tasks.

## Examples
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