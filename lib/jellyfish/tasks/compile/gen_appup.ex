defmodule Mix.Tasks.Compile.GenAppup do
  @moduledoc """
  Locate previous versions and triggers the appup files generation for hot upgrades.
  Automatically generates no-op appups for apps where only config changed.
  """
  @shortdoc "Generates appup files"
  use Mix.Task.Compiler

  alias Jellyfish.Cache
  alias Jellyfish.Releases.Appup
  alias Jellyfish.Releases.Helper

  @recursive true

  @impl true
  @spec run(term()) :: no_return
  def run(args) do
    # make sure loadpaths are updated
    Mix.Task.run("loadpaths", [])

    app_name = Mix.Project.config()[:app]
    build_path = Mix.Project.config()[:build_path] || "./_build"
    release_name = Keyword.get(args, :release_name, app_name)

    opts = %{
      app: app_name,
      upgrade_from: :latest,
      output_dir: "#{build_path}/#{Mix.env()}/rel/#{release_name}/"
    }

    :ok = trigger_gen_appup(app_name, opts)

    dependencies = Helper.prod_dependencies(Mix.Project.config()[:deps])

    # Generate dependencies appup (only once per library)
    Enum.each(dependencies, fn library ->
      if Cache.first_run_gen_appup?(library) do
        :ok = trigger_gen_appup(app_name, %{opts | app: library})
      end
    end)

    :ok
  end

  defp trigger_gen_appup(app_name, opts) do
    target_app = opts.app

    padded_name = String.pad_trailing("[#{target_app}]", 25)

    case do_gen_appup(opts) do
      {:ok, %{versions: versions, current: current, appup: false}} ->
        Cache.store_app_version(target_app, current)

        padded_versions = String.pad_trailing("versions: #{inspect(versions)}", 40)
        padded_current = String.pad_trailing("current: #{current}", 20)

        Mix.shell().info([
          :cyan,
          "#{padded_name} #{padded_versions} #{padded_current} - No appups"
        ])

        :ok

      {:ok, %{versions: versions, current: current, appup: true}} ->
        Cache.store_app_version(target_app, current)

        padded_versions = String.pad_trailing("versions: #{inspect(versions)}", 40)
        padded_current = String.pad_trailing("current: #{current}", 20)

        Mix.shell().info([
          :yellow,
          "#{padded_name} #{padded_versions} #{padded_current} - appups: #{app_name}/rel/appups/#{target_app}"
        ])

        :ok

      {:error, reason} ->
        Mix.shell().info("#{padded_name} error checking appup files reason: #{inspect(reason)}")

        {:error, reason}
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
    all_versions =
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

    previous_version = Map.delete(all_versions, v2)

    sorted_versions =
      previous_version
      |> Map.keys()
      |> sort_versions()

    if map_size(previous_version) == 0 do
      # NOTE: No previous releases exist
      {:ok, %{versions: Map.keys(all_versions), current: v2, appup: false}}
    else
      {v1, v1_path} =
        case opts[:upgrade_from] do
          :latest ->
            version = List.first(sorted_versions)
            {version, Map.fetch!(previous_version, version)}

          version ->
            case Map.get(previous_version, version) do
              nil ->
                System.halt(1)

              path ->
                {version, path}
            end
        end

      case Appup.make(app, v1, v2, v1_path, v2_path, _transforms = []) do
        {:error, _} = err ->
          err

        {:ok, appup} ->
          dir_path = Path.join(["rel", "appups", "#{app}"])

          deployex_file =
            """
            {
              "name": "#{app}",
              "from": "#{v1}",
              "to": "#{v2}"
            }
            """

          File.mkdir_p!(dir_path)
          :ok = write_term("#{dir_path}/#{v1}_to_#{v2}.appup", appup)
          File.write!("#{dir_path}/jellyfish.json", deployex_file)

          {:ok, %{versions: Map.keys(all_versions), current: v2, appup: true}}
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
