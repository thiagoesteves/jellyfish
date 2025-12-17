defmodule Jellyfish.CacheTest do
  use ExUnit.Case, async: false

  alias Jellyfish.Cache

  # Clean up process dictionary before each test to ensure isolation
  setup do
    # Store current process dictionary state
    old_dict = Process.get()

    # Clean all keys that might interfere with tests
    Process.get_keys()
    |> Enum.each(&Process.delete/1)

    on_exit(fn ->
      # Restore original state
      Process.get_keys()
      |> Enum.each(&Process.delete/1)

      Enum.each(old_dict, fn {k, v} -> Process.put(k, v) end)
    end)

    :ok
  end

  describe "first_run_gen_appup?/1" do
    test "returns true on first call for a library" do
      assert Cache.first_run_gen_appup?(:phoenix) == true
    end

    test "returns false on second call for the same library" do
      assert Cache.first_run_gen_appup?(:phoenix) == true
      assert Cache.first_run_gen_appup?(:phoenix) == false
    end

    test "returns false on subsequent calls for the same library" do
      assert Cache.first_run_gen_appup?(:ecto) == true
      assert Cache.first_run_gen_appup?(:ecto) == false
      assert Cache.first_run_gen_appup?(:ecto) == false
      assert Cache.first_run_gen_appup?(:ecto) == false
    end

    test "tracks different libraries independently" do
      assert Cache.first_run_gen_appup?(:phoenix) == true
      assert Cache.first_run_gen_appup?(:ecto) == true
      assert Cache.first_run_gen_appup?(:plug) == true

      assert Cache.first_run_gen_appup?(:phoenix) == false
      assert Cache.first_run_gen_appup?(:ecto) == false
      assert Cache.first_run_gen_appup?(:plug) == false
    end
  end

  describe "first_run_copy_appup?/1" do
    test "returns true on first call for a library" do
      assert Cache.first_run_copy_appup?(:cowboy) == true
    end

    test "returns false on second call for the same library" do
      assert Cache.first_run_copy_appup?(:cowboy) == true
      assert Cache.first_run_copy_appup?(:cowboy) == false
    end

    test "returns false on subsequent calls for the same library" do
      assert Cache.first_run_copy_appup?(:ranch) == true
      assert Cache.first_run_copy_appup?(:ranch) == false
      assert Cache.first_run_copy_appup?(:ranch) == false
    end

    test "tracks different libraries independently" do
      assert Cache.first_run_copy_appup?(:cowboy) == true
      assert Cache.first_run_copy_appup?(:ranch) == true

      assert Cache.first_run_copy_appup?(:cowboy) == false
      assert Cache.first_run_copy_appup?(:ranch) == false
    end
  end

  describe "first_run_gen_appup?/1 and first_run_copy_appup?/1 independence" do
    test "gen_appup and copy_appup track independently for same library" do
      # Gen appup first call
      assert Cache.first_run_gen_appup?(:phoenix) == true
      # Copy appup first call (should still be true)
      assert Cache.first_run_copy_appup?(:phoenix) == true

      # Both should now return false
      assert Cache.first_run_gen_appup?(:phoenix) == false
      assert Cache.first_run_copy_appup?(:phoenix) == false
    end

    test "calling copy_appup doesn't affect gen_appup state" do
      assert Cache.first_run_copy_appup?(:ecto) == true
      assert Cache.first_run_gen_appup?(:ecto) == true

      assert Cache.first_run_copy_appup?(:ecto) == false
      assert Cache.first_run_gen_appup?(:ecto) == false
    end
  end

  describe "store_app_version/2" do
    test "first time storing information returns nil" do
      refute Cache.store_app_version(:my_app, "1.2.3")
    end

    test "overwrites previous version information" do
      Cache.store_app_version(:my_app, "1.0.0")
      result = Cache.store_app_version(:my_app, "2.0.0")

      assert result == %{version: "1.0.0"}
      assert Cache.get_app(:my_app) == %{version: "2.0.0"}
    end

    test "stores different versions for different apps" do
      Cache.store_app_version(:app_one, "1.0.0")
      Cache.store_app_version(:app_two, "2.5.1")

      assert Cache.get_app(:app_one) == %{version: "1.0.0"}
      assert Cache.get_app(:app_two) == %{version: "2.5.1"}
    end

    test "handles version strings with various formats" do
      Cache.store_app_version(:app1, "1.2.3")
      Cache.store_app_version(:app2, "1.0.0-rc.1")
      Cache.store_app_version(:app3, "2.1.0+build.123")

      assert Cache.get_app(:app1) == %{version: "1.2.3"}
      assert Cache.get_app(:app2) == %{version: "1.0.0-rc.1"}
      assert Cache.get_app(:app3) == %{version: "2.1.0+build.123"}
    end
  end

  describe "get_app/1" do
    test "returns nil for non-existent application" do
      assert Cache.get_app(:non_existent) == nil
    end

    test "retrieves stored application version" do
      Cache.store_app_version(:my_app, "1.2.3")

      assert Cache.get_app(:my_app) == %{version: "1.2.3"}
    end

    test "returns most recently stored version" do
      Cache.store_app_version(:my_app, "1.0.0")
      Cache.store_app_version(:my_app, "1.1.0")
      Cache.store_app_version(:my_app, "2.0.0")

      assert Cache.get_app(:my_app) == %{version: "2.0.0"}
    end
  end

  describe "integration scenarios" do
    test "typical build workflow for single dependency" do
      # First, generate appup
      assert Cache.first_run_gen_appup?(:phoenix) == true
      Cache.store_app_version(:phoenix, "1.7.0")

      # Subsequent gen_appup calls should skip
      assert Cache.first_run_gen_appup?(:phoenix) == false

      # Copy appup (first time)
      assert Cache.first_run_copy_appup?(:phoenix) == true
      version_info = Cache.get_app(:phoenix)
      assert version_info == %{version: "1.7.0"}

      # Subsequent copy calls should skip
      assert Cache.first_run_copy_appup?(:phoenix) == false
    end

    test "multiple dependencies processed in sequence" do
      deps = [:phoenix, :ecto, :plug, :cowboy]

      # Generate phase
      Enum.each(deps, fn dep ->
        assert Cache.first_run_gen_appup?(dep) == true
        Cache.store_app_version(dep, "1.0.0")
        assert Cache.first_run_gen_appup?(dep) == false
      end)

      # Copy phase
      Enum.each(deps, fn dep ->
        assert Cache.first_run_copy_appup?(dep) == true
        assert Cache.get_app(dep) == %{version: "1.0.0"}
        assert Cache.first_run_copy_appup?(dep) == false
      end)
    end

    test "handling missing version data gracefully" do
      # Mark as processed without storing version
      assert Cache.first_run_gen_appup?(:mysterious_lib) == true
      assert Cache.first_run_gen_appup?(:mysterious_lib) == false

      # Attempting to get version returns nil
      assert Cache.get_app(:mysterious_lib) == nil
    end

    test "cache isolation between different operation types" do
      # An app can be in different states for different operations
      assert Cache.first_run_gen_appup?(:my_app) == true
      Cache.store_app_version(:my_app, "1.0.0")

      # Copy hasn't run yet
      assert Cache.first_run_copy_appup?(:my_app) == true

      # Both are now marked as processed
      assert Cache.first_run_gen_appup?(:my_app) == false
      assert Cache.first_run_copy_appup?(:my_app) == false

      # Version is still accessible
      assert Cache.get_app(:my_app) == %{version: "1.0.0"}
    end
  end

  describe "edge cases" do
    test "handles empty version string" do
      Cache.store_app_version(:app, "")
      assert Cache.get_app(:app) == %{version: ""}
    end

    test "multiple sequential stores and retrievals" do
      versions = ["1.0.0", "1.1.0", "1.2.0", "2.0.0"]

      Enum.each(versions, fn v ->
        Cache.store_app_version(:evolving_app, v)
        assert Cache.get_app(:evolving_app) == %{version: v}
      end)
    end

    test "first_run functions work with complex atom names" do
      assert Cache.first_run_gen_appup?(:"my-app-with-dashes") == true
      assert Cache.first_run_gen_appup?(:"my-app-with-dashes") == false

      assert Cache.first_run_copy_appup?(:"app.with.dots") == true
      assert Cache.first_run_copy_appup?(:"app.with.dots") == false
    end
  end
end
