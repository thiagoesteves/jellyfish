defmodule Distillery.Test.AppupTest do
  use ExUnit.Case
  alias Jellyfish.Releases.Appup

  @fixtures_path Path.join([__DIR__, "..", "fixtures"])

  @v1_path Path.join([@fixtures_path, "appup_beams", "test-0.1.0"])
  @v2_path Path.join([@fixtures_path, "appup_beams", "test-0.2.0"])
  @v3_path Path.join([@fixtures_path, "appup_beams", "test-0.3.0"])

  test "v1 -> v2" do
    # Add ServerB and ServerC gen_servers, update Server to reference ServerB,
    # and ServerB will reference ServerC
    expected =
      {:ok,
       {~c"0.2.0",
        [
          {~c"0.1.0",
           [
             {:add_module, Test.ServerB},
             {:add_module, Test.ServerC},
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.Supervisor, :supervisor}
           ]}
        ],
        [
          {~c"0.1.0",
           [
             {:delete_module, Test.ServerB},
             {:delete_module, Test.ServerC},
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.Supervisor, :supervisor}
           ]}
        ]}}

    assert ^expected = Appup.make(:test, "0.1.0", "0.2.0", @v1_path, @v2_path)
  end

  test "v2 -> v3" do
    # Server changes to reference ServerC, and ServerC changes to reference ServerB,
    # ServerB changes to no references
    expected =
      {:ok,
       {~c"0.3.0",
        [
          {~c"0.2.0",
           [
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.ServerB, {:advanced, []}, []},
             {:update, Test.ServerC, {:advanced, []}, []}
           ]}
        ],
        [
          {~c"0.2.0",
           [
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.ServerB, {:advanced, []}, []},
             {:update, Test.ServerC, {:advanced, []}, []}
           ]}
        ]}}

    assert ^expected = Appup.make(:test, "0.2.0", "0.3.0", @v2_path, @v3_path)
  end
end
