defmodule Jellyfish.Cache do
  @moduledoc """
  Provides process-dictionary-based caching for hot upgrade operations.

  This module manages ephemeral state during the build process to track which
  applications and dependencies have been processed for appup generation and copying.
  The cache is scoped to the current Mix process and does not persist across builds.

  ## Use Cases

  - **Deduplication**: Ensures appup files are generated only once per dependency
  - **Version Tracking**: Stores application version information for use across build tasks
  - **Build Coordination**: Coordinates state between `GenAppup` and `CopyAppup` tasks
  """

  ### ==========================================================================
  ### Public APIs
  ### ==========================================================================

  @doc """
  Checks if this is the first time generating appup files for a library.

  This function uses a boolean flag to track whether appup generation has been
  triggered for a specific library. The first call returns `true` and sets the
  flag to `false`, ensuring subsequent calls return `false`.
  """
  @spec first_run_gen_appup?(atom()) :: boolean()
  def first_run_gen_appup?(lib), do: first_run?("libraries-gen-appup", lib)

  @doc """
  Checks if this is the first time copying appup files for a library.

  Similar to `first_run_gen_appup?/1`, but tracks the copy operation separately.
  This allows the build process to coordinate generation and copying as distinct phases.
  """
  @spec first_run_copy_appup?(atom()) :: boolean()
  def first_run_copy_appup?(lib), do: first_run?("libraries-copy-appup", lib)

  @doc """
  Stores application version information in the process cache.

  The version is stored as a map with a `:version` key, allowing for future
  extension with additional metadata if needed.
  """
  @spec store_app_version(atom() | String.t(), String.t()) :: %{version: String.t()}
  def store_app_version(app, version) do
    Process.put(app, %{version: version})
  end

  @doc """
  Retrieves application information from the cache.

  Returns the data previously stored via `store_app_version/2`, or `nil` if
  no data exists for the given application.
  """
  @spec get_app(atom() | String.t()) :: %{version: String.t()} | nil
  def get_app(app), do: Process.get(app)

  ### ==========================================================================
  ### Private functions
  ### ==========================================================================
  defp first_run?(term, lib) do
    # Retrieve the flag, defaulting to true if not set
    data = Process.get({term, lib}, true)

    # If this is the first run (true), mark it as false for next time
    if data do
      Process.put({term, lib}, false)
    end

    # Return the original value
    data
  end
end
