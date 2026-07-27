defmodule JellyfishTest do
  use ExUnit.Case, async: false

  @app_name Mix.Project.config()[:app]
  @version Mix.Project.config()[:version]

  setup do
    Mix.Task.reenable("compile.gen_appup")
    Mix.Task.reenable("compile.copy_appup")

    on_exit(fn ->
      File.rm_rf!("rel")
      Mix.Task.reenable("compile.gen_appup")
      Mix.Task.reenable("compile.copy_appup")
    end)

    :ok
  end

  @tag :capture_log
  test "generate/1 runs the appup pipeline and copies the release file into the release path" do
    release_path = Path.join(System.tmp_dir!(), "jellyfish_generate_test")
    File.rm_rf!(release_path)

    version_path = Path.join(release_path, "version_path")
    File.mkdir_p!(version_path)
    File.mkdir_p!(Path.join(release_path, "releases"))

    File.write!(
      Path.join(version_path, "#{@app_name}.rel"),
      "{release, {\"#{@app_name}\", \"#{@version}\"}, {erts, \"1.0\"}, []}."
    )

    release = %Mix.Release{
      name: @app_name,
      version: @version,
      path: release_path,
      version_path: version_path,
      applications: [],
      boot_scripts: %{},
      config_providers: [],
      erts_source: nil,
      erts_version: "1.0",
      options: [],
      overlays: %{},
      steps: [:assemble]
    }

    assert %Mix.Release{} = Jellyfish.generate(release)

    rel_dest = Path.join([release_path, "releases", "#{@app_name}-#{@version}.rel"])
    assert File.exists?(rel_dest)
  end
end
