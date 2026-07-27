defmodule Mix.Tasks.Compile.GenAppupTest do
  use ExUnit.Case, async: false

  @app_name Mix.Project.config()[:app]

  setup do
    on_exit(fn -> File.rm_rf!("rel") end)

    :ok
  end

  test "returns :ok and skips appup generation when no previous release version exists" do
    # No release has been assembled under _build/test/rel/<app>, so there is
    # nothing to diff against and generation should be a no-op, not a crash.
    assert :ok = Mix.Tasks.Compile.GenAppup.run(release_name: @app_name)
  end
end
