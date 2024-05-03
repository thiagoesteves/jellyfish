defmodule Mix.Tasks.Compile.GenAppup do
  @moduledoc """
  Generate appup files for hot upgrades

  Copied/modified from https://github.com/bitwalker/distillery/blob/master/lib/distillery/tasks/gen.appup.ex

  The generated appup will be written to `rel/appups/<app>/<from>_to_<to>.appup`. You may name
  appups anything you wish in this directory, as long as they have a `.appup` extension. When you
  build a release, the appup generator will look for missing appups in this directory structure, and
  scan all `.appup` files for matching versions. If you have multiple appup files which match the current
  release, then the first one encountered will take precedence, which more than likely will depend on the
  sort order of the names.
  """
  @shortdoc "Genrates appup files"
  use Mix.Task.Compiler

  alias Jellyfish.Releases.Appups

  @recursive true

  @impl true
  @spec run(term()) :: no_return
  def run(_args) do
    # make sure loadpaths are updated
    Mix.Task.run("loadpaths", [])

    app_name = Mix.Project.config()[:app]

    opts = %{
      app: app_name,
      upgrade_from: :latest,
      output_dir: "_build/#{Mix.env()}/rel/#{app_name}/"
    }

    case do_gen_appup(opts) do
      :ok ->
        IO.puts(
          "You can find your generated appups in rel/appups/#{app_name}/ with the .appup extension"
        )

      {:error, _} ->
        IO.puts("No appups, nothing to move to the release")
    end
  end

  defp do_gen_appup(opts) do
    app = opts[:app]
    output_dir = opts[:output_dir]

    # Does app exist?
    case Application.load(app) do
      :ok ->
        :ok

      {:error, {:already_loaded, _}} ->
        :ok

      {:error, _} ->
        System.halt(1)
    end

    v2 =
      app
      |> Application.spec()
      |> Keyword.get(:vsn)
      |> List.to_string()

    v2_path = Application.app_dir(app)

    # Look for app versions in release directory
    available_versions =
      Path.join([output_dir, "lib", "#{app}-*"])
      |> Path.wildcard()
      |> Enum.map(fn appdir ->
        {:ok, [{:application, ^app, meta}]} =
          Path.join([appdir, "ebin", "#{app}.app"])
          |> read_terms()

        version =
          meta
          |> Keyword.fetch!(:vsn)
          |> List.to_string()

        {version, appdir}
      end)
      |> Map.new()
      |> Map.delete(v2)

    sorted_versions =
      available_versions
      |> Map.keys()
      |> sort_versions()

    if map_size(available_versions) == 0 do
      {:error, "No previous releases exist"}
    else
      {v1, v1_path} =
        case opts[:upgrade_from] do
          :latest ->
            version = List.first(sorted_versions)
            {version, Map.fetch!(available_versions, version)}

          version ->
            case Map.get(available_versions, version) do
              nil ->
                System.halt(1)

              path ->
                {version, path}
            end
        end

      case Appups.make(app, v1, v2, v1_path, v2_path, _transforms = []) do
        {:error, _} = err ->
          err

        {:ok, appup} ->
          appup_path = Path.join(["rel", "appups", "#{app}", "#{v1}_to_#{v2}.appup"])
          File.mkdir_p!(Path.dirname(appup_path))
          :ok = write_term(appup_path, appup)
      end
    end
  end

  defp read_terms(path) when is_binary(path) do
    case :file.consult(path) do
      {:ok, _} = result ->
        result

      {:error, reason} ->
        {:error, {:read_terms, :file, reason}}
    end
  end

  @spec sort_versions([binary]) :: [binary]
  defp sort_versions(versions) do
    versions
    |> classify_versions()
    |> parse_versions()
    |> Enum.sort(&compare_versions/2)
    |> Enum.map(&elem(&1, 0))
  end

  @git_describe_pattern ~r/(?<ver>\d+\.\d+\.\d+)-(?<commits>\d+)-(?<sha>[A-Ga-g0-9]+)/
  defp classify_versions([]), do: []

  defp classify_versions([ver | versions]) when is_binary(ver) do
    # Special handling for git-describe versions
    compare_ver =
      case Regex.named_captures(@git_describe_pattern, ver) do
        nil ->
          {:standard, ver}

        %{"ver" => version, "commits" => n, "sha" => sha} ->
          {:describe, <<version::binary, ?+, n::binary, ?-, sha::binary>>, String.to_integer(n)}
      end

    [{ver, compare_ver} | classify_versions(versions)]
  end

  defp parse_versions([]),
    do: []

  defp parse_versions([{raw, {:standard, ver}} | versions]) when is_binary(ver) do
    [{raw, parse_version(ver), 0} | parse_versions(versions)]
  end

  defp parse_versions([{raw, {:describe, ver, commits_since}} | versions]) when is_binary(ver) do
    [{raw, parse_version(ver), commits_since} | parse_versions(versions)]
  end

  defp parse_version(ver) when is_binary(ver) do
    parsed = Version.parse!(ver)
    {:v, parsed}
  rescue
    Version.InvalidVersionError ->
      {:other, ver}
  end

  defp compare_versions({_, {:v, v1}, v1_commits_since}, {_, {:v, v2}, v2_commits_since}) do
    case Version.compare(v1, v2) do
      :gt ->
        true

      :lt ->
        false

      :eq ->
        # Same version, so compare any incremental changes
        # This is based on the describe syntax, but is defaulted to 0
        # for non-describe versions
        v1_commits_since > v2_commits_since
    end
  end

  defp compare_versions({_, {_, v1}, _}, {_, {_, v2}, _}), do: v1 > v2

  defp write_term(path, term) do
    path = String.to_charlist(path)
    contents = :io_lib.fwrite(~c"~p.\n", [term])

    case :file.write_file(path, contents, encoding: :utf8) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, {:write_terms, :file, reason}}
    end
  end
end
