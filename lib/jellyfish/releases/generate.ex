defmodule Jellyfish.Releases.Generate do
  @moduledoc """
  This module is responsible for generating, moving and packing the release with appup files.
  """

  @spec appup_files(Mix.Release.t()) :: Mix.Release.t()
  def appup_files(%Mix.Release{name: name, version: vsn, path: path, version_path: vp} = release) do
    Mix.shell().info([
      :green,
      "* hot-upgrade ",
      :reset,
      "Checking if previous versions are available"
    ])

    Mix.Task.run("compile.gen_appup", release_name: name)
    Mix.Task.run("compile.copy_appup")

    rel_source = Path.join(vp, "#{name}.rel")
    rel_dest = Path.join([path, "releases", "#{name}-#{vsn}.rel"])

    message = "copying release file to #{rel_dest}"
    Mix.shell().info([:green, "* hot-upgrade ", :reset, message])

    File.cp!(rel_source, rel_dest)

    release
  end
end
