defmodule Jellyfish.Releases.HelperTest do
  use ExUnit.Case, async: true

  alias Jellyfish.Releases.Helper

  describe "prod_dependencies/1" do
    test "includes simple dependencies with version string" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:ecto, "~> 3.10"},
        {:plug, "~> 1.14"}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix, :ecto, :plug]
    end

    test "excludes dev-only dependencies" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:credo, only: :dev},
        {:dialyxir, only: :dev}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "excludes test-only dependencies" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:ex_machina, only: :test},
        {:mock, only: :test}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "excludes dependencies with only: [:dev, :test]" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:credo, only: [:dev, :test]},
        {:ecto, "~> 3.10"}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix, :ecto]
    end

    test "includes dependencies with only: [:prod]" do
      deps = [
        {:phoenix, "~> 1.7", only: [:prod]},
        {:credo, only: [:dev, :test]}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "includes dependencies with only: [:dev, :prod]" do
      deps = [
        {:mix_test_watch, only: :dev},
        {:logger_backend, only: [:dev, :prod]},
        {:credo, only: :test}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:logger_backend]
    end

    test "excludes dependencies with runtime: false" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:credo, "~> 1.7", runtime: false}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "excludes dependencies with compile: false" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:some_tool, compile: false}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "excludes dependencies with app: false" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:elixir_make, app: false}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "excludes dependencies with in_umbrella: true" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:my_app_core, in_umbrella: true}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "handles complex dependency specifications" do
      deps = [
        {:phoenix, "~> 1.7", only: :prod, runtime: true},
        {:ecto, "~> 3.10"},
        {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
        {:ex_doc, only: :dev},
        {:jason, "~> 1.4", runtime: true}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix, :ecto, :jason]
    end

    test "handles empty dependency list" do
      assert Helper.prod_dependencies([]) == []
    end

    test "preserves order of dependencies" do
      deps = [
        {:aaa, "~> 1.0"},
        {:zzz, "~> 2.0"},
        {:mmm, "~> 3.0"}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:aaa, :zzz, :mmm]
    end

    test "handles git dependencies" do
      deps = [
        {:phoenix, github: "phoenixframework/phoenix"},
        {:plug, git: "https://github.com/elixir-plug/plug.git"}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix, :plug]
    end

    test "handles path dependencies" do
      deps = [
        {:my_local_lib, path: "../my_local_lib"},
        {:phoenix, "~> 1.7"}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:my_local_lib, :phoenix]
    end

    test "handles mixed dependency formats" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:ecto, only: [:prod, :dev]},
        {:plug, "~> 1.14", runtime: true},
        {:credo, only: :dev},
        {:jason, github: "michalmuskala/jason", only: :prod}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix, :ecto, :plug, :jason]
    end

    test "excludes when multiple exclusion conditions are met" do
      deps = [
        {:phoenix, "~> 1.7"},
        {:dev_tool, only: :dev, runtime: false, compile: false}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "includes when all inclusion conditions are met" do
      deps = [
        {:phoenix, "~> 1.7", runtime: true, compile: true, app: true, only: :prod}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix]
    end

    test "handles hex package dependencies" do
      deps = [
        {:phoenix, "~> 1.7", hex: :phoenix_framework},
        {:custom_package, "~> 2.0", hex: :my_custom_hex}
      ]

      result = Helper.prod_dependencies(deps)
      assert result == [:phoenix, :custom_package]
    end
  end
end
