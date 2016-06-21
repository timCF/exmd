defmodule ExmdTest do
	use ExUnit.Case
	doctest Exmd

	defp write(data) do
		IO.inspect(data)
		IO.puts(data)
		File.write!("./test/output.md", data)
	end

	test "the truth" do
		%{
			int: 100,
			float: 7.5,
			list: [
				"hello && world",
				123,
				<<1,3,255,5>>,
				%{foo: [], bar: %{}, baz: :world, buf: nil}
			]
		}
		|> Exmd.convert
		|> write
		assert 1 + 1 == 2
	end
end
