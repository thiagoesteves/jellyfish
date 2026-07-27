defmodule Mix.Tasks.Compile.CopyAppupTest do
  use ExUnit.Case, async: false

  @app_name Mix.Project.config()[:app]
  @version Mix.Project.config()[:version]
  @appup_dir "rel/appups/#{@app_name}"

  setup do
    File.rm_rf!(@appup_dir)

    on_exit(fn -> File.rm_rf!("rel") end)

    :ok
  end

  test "returns :ok without touching the release when no appup file exists" do
    release_path = Path.join(System.tmp_dir!(), "jellyfish_copy_appup_test_no_appup")
    File.rm_rf!(release_path)

    assert :ok = Mix.Tasks.Compile.CopyAppup.run(release_path: release_path)
  end

  @tag :capture_log
  test "returns an error diagnostic, instead of crashing, when more than one appup file matches the target version" do
    File.mkdir_p!(@appup_dir)
    File.write!(Path.join(@appup_dir, "0.1.0_to_#{@version}.appup"), "{}.")
    File.write!(Path.join(@appup_dir, "0.1.1_to_#{@version}.appup"), "{}.")
    File.write!(Path.join(@appup_dir, "jellyfish.json"), "{}")

    release_path = Path.join(System.tmp_dir!(), "jellyfish_copy_appup_test_ambiguous")
    File.rm_rf!(release_path)

    assert {:error, [%Mix.Task.Compiler.Diagnostic{compiler_name: "CopyAppup"}]} =
             Mix.Tasks.Compile.CopyAppup.run(release_path: release_path)
  end

  test "copies the appup and jellyfish files to the release when exactly one match is found" do
    File.mkdir_p!(@appup_dir)
    File.write!(Path.join(@appup_dir, "0.1.0_to_#{@version}.appup"), "{}.")
    File.write!(Path.join(@appup_dir, "jellyfish.json"), "{}")

    release_path = Path.join(System.tmp_dir!(), "jellyfish_copy_appup_test_single_match")
    destination_dir = "#{release_path}/lib/#{@app_name}-#{@version}/ebin"
    File.rm_rf!(release_path)
    File.mkdir_p!(destination_dir)

    assert :ok = Mix.Tasks.Compile.CopyAppup.run(release_path: release_path)
    assert File.exists?("#{destination_dir}/#{@app_name}.appup")
    assert File.exists?("#{destination_dir}/jellyfish.json")
  end
end
