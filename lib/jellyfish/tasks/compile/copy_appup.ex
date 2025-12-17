defmodule Mix.Tasks.Compile.CopyAppup do
  @moduledoc """
  This Mix task copies the appup and Jellyfish metadata files to their respective release directories.

  Copied/modified from https://preview.hex.pm/preview/forecastle/0.1.2/show/lib/mix/tasks/compile/appup.ex
  """
  @shortdoc "Copying appup/jellyfish files to the release folder"
  use Mix.Task.Compiler

  require Logger

  @recursive true

  @impl true
  @spec run(any()) :: :ok | {:error, [Mix.Task.Compiler.Diagnostic.t(), ...]}
  def run(args) do
    # make sure loadpaths are updated
    Mix.Task.run("loadpaths", [])

    version = Mix.Project.config()[:version]
    app_name = Mix.Project.config()[:app]

    release_path = Keyword.fetch!(args, :release_path)
    hot_upgrade_deps = Keyword.fetch!(args, :hot_upgrade_deps)

    # Trigger application copy
    :ok = trigger_copy(release_path, app_name, version)

    # Trigger dependencies copy (only once)
    if first_run_copy?() do
      Enum.each(hot_upgrade_deps, fn dep_app ->
        %{version: dep_version} = Process.get(dep_app)
        :ok = trigger_copy(release_path, dep_app, dep_version)
      end)
    end

    :ok
  end

  defp trigger_copy(release_path, app_name, version) do
    appup_source = "rel/appups/#{app_name}"

    with [appup_file] <- Path.wildcard("#{appup_source}/*_to_#{version}.appup"),
         [jellyfish_file] <- Path.wildcard("#{appup_source}/jellyfish.json") do
      destination_dir = "#{release_path}/lib/#{app_name}-#{version}/ebin"

      edit_appup? = System.get_env("EDIT_APPUP")

      if edit_appup? do
        IO.puts(
          "#{IO.ANSI.cyan()}------------------------------------------------------------------------------"
        )

        IO.gets(
          "Press any key when you're done editing #{IO.ANSI.magenta()}#{appup_file}\n#{IO.ANSI.cyan()}------------------------------------------------------------------------------\n"
        )
      end

      File.copy(appup_file, "#{destination_dir}/#{app_name}.appup")

      File.copy(jellyfish_file, "#{destination_dir}/jellyfish.json")

      :ok
    else
      [] = _appups ->
        :ok

      error ->
        Logger.error("Error copying appup to release, #{inspect(error)}")

        {:error, [diagnostic(:warning, "Appup file not found: #{app_name}")]}
    end
  end

  defp diagnostic(severity, message, file \\ Mix.Project.project_file()) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "CopyAppup",
      file: file,
      position: nil,
      severity: severity,
      message: message
    }
  end

  defp first_run_copy? do
    data = Process.get("libraries-copy-appup", true)

    if data do
      Process.put("libraries-copy-appup", false)
    end

    data
  end
end
