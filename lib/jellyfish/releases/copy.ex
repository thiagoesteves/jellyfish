defmodule Jellyfish.Releases.Copy do
  @moduledoc """
  This module is responsible for providing the release file copy method

  Copied/modified from https://preview.hex.pm/preview/forecastle/0.1.2/show/lib/forecastle.ex
  """

  @spec relfile(Mix.Release.t()) :: Mix.Release.t()
  def relfile(%Mix.Release{name: name, version: vsn, path: path, version_path: vp} = release) do
    rel_source = Path.join(vp, "#{name}.rel")
    rel_dest = Path.join([path, "releases", "#{name}-#{vsn}.rel"])

    message = "copying release file to #{rel_dest}"
    Mix.shell().info([:green, "* hot-upgrade ", :reset, message])

    File.cp!(rel_source, rel_dest)

    release
  end
end
