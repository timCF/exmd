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

	def convert(some, opts \\ %{escape: 2}), do: (some |> convert_process(opts, 0) |> String.strip)

	defp convert_process(kv = %{}, opts = %{}, level) when (kv != %{}) do
		Map.to_list(kv)
		|> Enum.sort(fn
			{:__struct__, _}, _ -> true
			{_, int}, _ when is_integer(int) -> true
			{_, fl}, {_, int} when is_float(fl) and is_integer(int) -> false
			{_, fl}, _ when is_float(fl) -> true
			_, _ -> false
		end)
		|> reducekv(opts, level)
	end
	defp convert_process(lst = [_|_], opts = %{}, level) do
		case Keyword.keyword?(lst) do
			true -> reducekv(lst, opts, level)
			false ->
				Enum.reduce(lst, "", fn(v, acc) ->
					case nested?(v) do
						false -> acc<>tabs(level)<>convert_simple(v, opts)
						true -> acc<>tabs(level)<>convert_process(v, opts, level+1)
					end
				end)
		end
	end
	defp convert_process(some, opts = %{}, _), do: convert_simple(some, opts)

	defp tabs(0), do: "\n- "
	defp tabs(level), do: "\n"<>Enum.reduce(1..level, "", fn(_, acc) -> acc<>"  " end)<>"- "

	defp nested?(v) when is_list(v) or is_map(v), do: ((v != %{}) and (v != []))
	defp nested?(_), do: false

	defp convert_simple(some, opts) when ((some == %{}) or (some == [])), do: "*#{some |> inspect |> escape(opts)}*"
	defp convert_simple(some, opts) when is_integer(some), do: "**#{some |> Integer.to_string |> escape(opts)}**"
	defp convert_simple(some, opts) when is_float(some), do: "**_#{some |> Float.to_string([decimals: 6, compact: true]) |> escape(opts)}_**"
	defp convert_simple(some, opts) do
		some = Maybe.maybe_to_string(some)
		case String.valid?(some) do
			true ->
				case String.contains?(some, " ") do
					true -> "\"#{some |> escape(opts)}\""
					false -> some |> escape(opts)
				end
			false ->
				"*#{some |> inspect |> escape(opts)}*"
		end
	end

	defp reducekv(kv, opts, level) do
		Enum.reduce(kv, "", fn({k,v},acc) ->
			case nested?(v) do
				false -> acc<>tabs(level)<>convert_simple(k, opts)<>": "<>convert_simple(v, opts)
				true -> acc<>tabs(level)<>convert_simple(k, opts)<>convert_process(v, opts, level+1)
			end
		end)
	end

	defp escape(string, %{escape: 0}), do: string
	defp escape(string, %{escape: 1}) do
		string
		|> String.replace("&","&amp;")
		|> String.replace("<","&lt;")
		|> String.replace(">","&gt;")
	end
	defp escape(string, opts = %{escape: 2}) do
		Regex.replace(~r/[\\\`\*\_\{\}\[\]\(\)\#\+\-\.\!]/, string, fn(some) -> "\\"<>some end)
		|> escape(%{opts | escape: 1})
	end

end
