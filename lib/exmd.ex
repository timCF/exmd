defmodule Exmd do
	use Application

	defstruct marker: "-",
			  escape: 2

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

	def convert(some, opts \\ %Exmd{}) do
		case convert_process(some, opts, 0) do
			<<"\n", rest::binary>> -> rest
			text -> text
		end
	end

	defp convert_process(kv = %{}, opts = %Exmd{}, level) when (kv != %{}) do
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
	defp convert_process(lst = [_|_], opts = %Exmd{}, level) do
		case Keyword.keyword?(lst) do
			true -> reducekv(lst, opts, level)
			false ->
				Enum.reduce(lst, "", fn(v, acc) ->
					case nested?(v) do
						false -> acc<>tabs(level, opts)<>convert_simple(v, opts)
						true -> acc<>tabs(level, opts)<>convert_process(v, opts, level+1)
					end
				end)
		end
	end
	defp convert_process(some, opts = %Exmd{}, _), do: convert_simple(some, opts)

	defp tabs(0, %Exmd{marker: marker}), do: "\n#{marker} "
	defp tabs(level, %Exmd{marker: marker}), do: "\n"<>Enum.reduce(1..level, "", fn(_, acc) -> acc<>"  " end)<>"#{marker} "

	defp nested?(v) when is_list(v) or is_map(v), do: ((v != %{}) and (v != []))
	defp nested?(_), do: false

	defp convert_simple(some, opts = %Exmd{}) when ((some == %{}) or (some == [])), do: "*#{some |> inspect |> escape(opts)}*"
	defp convert_simple(some, opts = %Exmd{}) when is_integer(some), do: "**#{some |> Integer.to_string |> escape(opts)}**"
	defp convert_simple(some, opts = %Exmd{}) when is_float(some), do: "**_#{some |> Float.to_string([decimals: 6, compact: true]) |> escape(opts)}_**"
	defp convert_simple(some, opts = %Exmd{}) do
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

	defp reducekv(kv, opts = %Exmd{}, level) do
		Enum.reduce(kv, "", fn({k,v},acc) ->
			case nested?(v) do
				false -> acc<>tabs(level, opts)<>convert_simple(k, opts)<>": "<>convert_simple(v, opts)
				true -> acc<>tabs(level, opts)<>convert_simple(k, opts)<>convert_process(v, opts, level+1)
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
	defp escape(string, opts = %Exmd{escape: 2}) do
		Regex.replace(~r/[\\\`\*\_\{\}\[\]\(\)\#\+\-\.\!]/, string, fn(some) -> "\\"<>some end)
		|> escape(%Exmd{opts | escape: 1})
	end

end
