defmodule Mix.Tasks.Compile.Appup do
  @moduledoc """
  This module is responsible for generating appups between two releases.

  Copied/modified from https://preview.hex.pm/preview/forecastle/0.1.2/show/lib/mix/tasks/compile/appup.ex
  """
  @shortdoc "Compiles appup files"
  use Mix.Task.Compiler

  require Logger

  @impl true
  @spec run(any()) :: :ok | {:error, [Mix.Task.Compiler.Diagnostic.t(), ...]}
  def run(_args) do
    # make sure loadpaths are updated
    Mix.Task.run("loadpaths", [])

    version = Mix.Project.config()[:version]
    app_name = Mix.Project.config()[:app]

    with [file] <- Path.wildcard("rel/appups/#{app_name}/*_to_#{version}.appup") do
      dst = Path.join(Mix.Project.compile_path(), "holidex.appup")

      edit_appup? = System.get_env("EDIT_APPUP")

      if edit_appup? do
        IO.puts(
          "#{IO.ANSI.cyan()}------------------------------------------------------------------------------"
        )

        IO.gets(
          "Press any key when you're done editing #{IO.ANSI.magenta()}#{file}\n#{IO.ANSI.cyan()}------------------------------------------------------------------------------\n"
        )
      end

      File.copy(file, dst)
      :ok
    else
      [] = _appups ->
        :ok

      error ->
        Logger.error("Error copying appup to release, #{inspect(error)}")

        {:error, [diagnostic(:warning, "Appup file not found: #{Mix.Project.config()[:appup]}")]}
    end
  end

  defp diagnostic(severity, message, file \\ Mix.Project.project_file()) do
    %Mix.Task.Compiler.Diagnostic{
      compiler_name: "Appup",
      file: file,
      position: nil,
      severity: severity,
      message: message
    }
  end
end
