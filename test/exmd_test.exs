defmodule ExmdTest do
	use ExUnit.Case
	doctest Exmd

	@data 	%{
				int: 100,
				float: 7.5,
				list: [
					"hello && world",
					123,
					<<1,3,255,5>>,
					%{foo: [], bar: %{}, baz: :world, buf: nil}
				]
			}

	defp write(data) do
		IO.puts("")
		IO.inspect(data)
		File.write!("./test/output.md", data)
	end

	test "the truth" do
		Exmd.convert(@data) |> write
		"\n"<>Exmd.convert(@data, %{escape: 2}) |> IO.puts
		"\n"<>Exmd.convert(@data, %{escape: 1}) |> IO.puts
		"\n"<>Exmd.convert(@data, %{escape: 0}) |> IO.puts
		assert 1 + 1 == 2
	end
end
