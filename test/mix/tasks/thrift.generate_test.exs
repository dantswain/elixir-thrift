defmodule Mix.Tasks.Thrift.GenerateTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @project_root Path.expand("../../../", __DIR__)
  @fixture_project Path.join(@project_root, "test/fixtures/app")

  setup do
    on_exit(fn -> File.rm_rf!(Path.join(@fixture_project, "lib")) end)
    :ok
  end

  test "not specifying any Thrift files" do
    in_fixture fn ->
      assert run([]) == ""
    end
  end

  test "specifying multiple Thrift files" do
    in_fixture fn ->
      with_project_config [], fn ->
        output = run(["thrift/StressTest.thrift", "thrift/ThriftTest.thrift"])
        assert output =~ "Parsing thrift/StressTest.thrift"
        assert output =~ "Parsing thrift/ThriftTest.thrift"
        assert File.exists?("lib/generated/service.ex")
        assert File.exists?("lib/thrift_test/thrift_test.ex")
      end
    end
  end

  test "specifying a non-existent Thrift file" do
    in_fixture fn ->
      assert_raise Mix.Error, ~r/could not read file/, fn ->
        run(["missing.thrift"])
      end
    end
  end

  test "specifying an invalid Thrift file" do
    in_fixture fn ->
      assert_raise Mix.Error, ~r/Error parsing/, fn ->
        run([__ENV__.file])
      end
    end
  end

  test "specifying an alternate output directory (--out)" do
    in_fixture fn ->
      with_project_config [], fn ->
        run(["--out", "lib/thrift", "thrift/ThriftTest.thrift"])
        assert File.exists?("lib/thrift/thrift_test/thrift_test.ex")
      end
    end
  end

  test "specifying an include path (--include)" do
    in_fixture fn ->
      with_project_config [], fn ->
        run(~w(--include thrift thrift/include/Include.thrift))
        assert File.exists?("lib/thrift_test/thrift_test.ex")
      end
    end
  end

  defp run(args) when is_list(args), do: run(:stdio, args)
  defp run(device, args) when device in [:stdio, :stderr] and is_list(args) do
    args = ["--verbose" | args]
    capture_io(device, fn -> Mix.Tasks.Thrift.Generate.run(args) end)
  end

  defp in_fixture(fun) do
    File.cd!(@fixture_project, fun)
  end

  defp with_project_config(config, fun) do
    Mix.Project.in_project(:app, @fixture_project, config, fn(_) -> fun.() end)
  end
end
