defmodule Exmd do
	use Application

	# See http://elixir-lang.org/docs/stable/elixir/Application.html
	# for more information on OTP Applications
	def start(_type, _args) do
		import Supervisor.Spec, warn: false

		children = [
		# Define workers and child supervisors to be supervised
		# worker(Exmd.Worker, [arg1, arg2, arg3]),
		]

		# See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
		# for other strategies and supported options
		opts = [strategy: :one_for_one, name: Exmd.Supervisor]
		Supervisor.start_link(children, opts)
	end

	def convert(any, level \\ 0)
	def convert(kv = %{}, level) when (kv != %{}) do
		Enum.to_list(kv)
		|> Enum.sort(fn
			{:__struct__, _}, _ -> true
			{_, int}, _ when is_integer(int) -> true
			{_, fl}, {_, int} when is_float(fl) and is_integer(int) -> false
			{_, fl}, _ when is_float(fl) -> true
			_, _ -> false
		end)
		|> reducekv(level)
	end
	def convert(lst = [_|_], level) do
		case Keyword.keyword?(lst) do
			true -> reducekv(lst, level)
			false ->
				Enum.reduce(lst, "", fn(v, acc) ->
					case nested?(v) do
						false -> acc<>tabs(level)<>convert_simple(v)
						true -> acc<>tabs(level)<>convert(v, level+1)
					end
				end)
		end
	end
	def convert(some, _), do: convert_simple(some)

	defp tabs(0), do: "\n- "
	defp tabs(level), do: "\n"<>Enum.reduce(1..level, "", fn(_, acc) -> acc<>"  " end)<>"- "

	defp nested?(v) when is_list(v) or is_map(v), do: ((v != %{}) and (v != []))
	defp nested?(_), do: false

	defp convert_simple(some) when ((some == %{}) or (some == [])), do: "*#{some |> inspect |> escape}*"
	defp convert_simple(some) when is_integer(some), do: "**#{some |> Integer.to_string |> escape}**"
	defp convert_simple(some) when is_float(some), do: "**_#{some |> Float.to_string |> escape}_**"
	defp convert_simple(some) do
		some = Maybe.maybe_to_string(some)
		case String.valid?(some) do
			true ->
				case String.contains?(some, " ") do
					true -> "\"#{some |> escape}\""
					false -> some |> escape
				end
			false ->
				"*#{some |> inspect |> escape}*"
		end
	end

	defp reducekv(kv, level) do
		Enum.reduce(kv, "", fn({k,v},acc) ->
			case nested?(v) do
				false -> acc<>tabs(level)<>convert_simple(k)<>": "<>convert_simple(v)
				true -> acc<>tabs(level)<>convert_simple(k)<>convert(v, level+1)
			end
		end)
	end

	defp escape(string) do
		Regex.replace(~r/[\\\`\*\_\{\}\[\]\(\)\#\+\-\.\!]/, string, fn(some) -> "\\"<>some end)
		|> String.replace("&","&amp;")
		|> String.replace("<","&lt;")
		|> String.replace(">","&gt;")
	end

end
