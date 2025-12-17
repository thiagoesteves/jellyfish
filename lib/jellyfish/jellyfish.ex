defmodule Jellyfish do
  @moduledoc """
  This module is responsible for generating appup/jellyfish files and moving it to the release folder.
  """

  @spec generate(Mix.Release.t()) :: Mix.Release.t()
  def generate(%Mix.Release{name: name, version: vsn, path: path, version_path: vp} = release) do
    Mix.shell().info([
      :green,
      "* hot-upgrade ",
      :reset,
      "Checking if previous versions are available"
    ])

    hot_upgrade_deps = Mix.Project.config()[:hot_upgrade_deps] || []

    Mix.Task.run("compile.gen_appup", release_name: name, hot_upgrade_deps: hot_upgrade_deps)
    Mix.Task.run("compile.copy_appup", release_path: path, hot_upgrade_deps: hot_upgrade_deps)

    rel_source = Path.join(vp, "#{name}.rel")
    rel_dest = Path.join([path, "releases", "#{name}-#{vsn}.rel"])

    message = "copying release file to #{rel_dest}"
    Mix.shell().info([:green, "* hot-upgrade ", :reset, message])

    File.cp!(rel_source, rel_dest)

    release
  end
end
