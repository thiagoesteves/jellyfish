defmodule Jellyfish.Releases.Helper do
  @moduledoc """
  Helper functions for managing dependencies in release builds.

  This module provides utilities to filter and identify production dependencies
  from a Mix project's dependency list, which is useful when creating releases
  or analyzing which dependencies will be included in production environments.
  """

  ### ==========================================================================
  ### Public APIs
  ### ==========================================================================

  @doc """
  Filters a list of dependencies to return only those that should be included in production.

  This function analyzes dependency specifications and their options to determine
  which dependencies are actually needed in a production release. It considers
  various dependency options such as `:runtime`, `:only`, `:in_umbrella`, `:compile`,
  and `:app` to make this determination.

  For more information about Mix dependencies, see:
  https://hexdocs.pm/mix/Mix.Tasks.Deps.html
  """
  @spec prod_dependencies(list()) :: list(atom())
  def prod_dependencies(deps) do
    Enum.reduce(deps, [], fn
      {lib, requirement}, acc when is_binary(requirement) ->
        acc ++ [lib]

      {lib, options}, acc ->
        if dependency_in_prod?(options) do
          acc ++ [lib]
        else
          acc
        end

      {lib, _requirement, options}, acc ->
        if dependency_in_prod?(options) do
          acc ++ [lib]
        else
          acc
        end
    end)
  end

  ### ==========================================================================
  ### Private functions
  ### ==========================================================================
  defp dependency_in_prod?(options) do
    runtime? = Keyword.get(options, :runtime, true)

    prod? =
      case Keyword.get(options, :only) do
        env when is_list(env) ->
          :prod in env

        env when env in [:dev, :test] ->
          false

        _ ->
          true
      end

    in_umbrella? = Keyword.get(options, :in_umbrella, false)
    compile? = Keyword.get(options, :compile, true)
    app? = Keyword.get(options, :app, true)

    runtime? and prod? and app? and compile? and not in_umbrella?
  end
end
