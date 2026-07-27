defmodule Jellyfish do
  @moduledoc """
  This module is responsible for generating appup/jellyfish files and moving it to the release folder.
  """

  @doc """
  Release step that generates appup files and copies them into the release.

  Meant to be plugged into a release's `:steps`, after `:assemble`:

      releases: [
        my_app: [
          steps: [:assemble, &Jellyfish.generate/1, :tar]
        ]
      ]

  It runs the `compile.gen_appup` and `compile.copy_appup` Mix compiler tasks
  for the release's app and its production dependencies, then copies the
  freshly assembled `.rel` file into the release's `releases/` directory.
  Returns the given `release` unchanged, as required by the `:steps` contract.
  """
  @spec generate(Mix.Release.t()) :: Mix.Release.t()
  def generate(%Mix.Release{name: name, version: vsn, path: path, version_path: vp} = release) do
    Mix.shell().info([
      :green,
      "* hot-upgrade ",
      :reset,
      "Checking if previous versions are available"
    ])

    Mix.Task.run("compile.gen_appup", release_name: name)
    Mix.Task.run("compile.copy_appup", release_path: path)

    rel_source = Path.join(vp, "#{name}.rel")
    rel_dest = Path.join([path, "releases", "#{name}-#{vsn}.rel"])

    message = "copying release file to #{rel_dest}"
    Mix.shell().info([:green, "* hot-upgrade ", :reset, message])

    File.cp!(rel_source, rel_dest)

    release
  end
end
