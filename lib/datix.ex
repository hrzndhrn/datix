defmodule Datix do
  @moduledoc """
  A date-time parser using `Calendar.strftime` format strings.
  """

  @type t :: %{
          optional(:am_pm) => :am | :pm,
          optional(:day) => pos_integer(),
          optional(:day_of_week) => pos_integer(),
          optional(:day_of_year) => pos_integer(),
          optional(:hour) => pos_integer(),
          optional(:hour_12) => pos_integer(),
          optional(:microsecond) => pos_integer(),
          optional(:minute) => pos_integer(),
          optional(:month) => pos_integer(),
          optional(:quarter) => pos_integer(),
          optional(:second) => pos_integer(),
          optional(:year) => pos_integer(),
          optional(:year_2_digit) => pos_integer(),
          optional(:zone_abbr) => String.t(),
          optional(:zone_offset) => integer()
        }

  @doc """
  Parses a date-time string according to the given `format`.

  See the Calendar.strftime documentation for how to specify a format string.

  ## Options

    * `:preferred_date` - a string for the preferred format to show dates,
      it can't contain the `%x` format and defaults to `"%Y-%m-%d"`
      if the option is not received

    *  `:month_names` - a list of the month names, if the option is not received
      it defaults to a list of month names in English

    * `:abbreviated_month_names` - a list of abbreviated month names, if the
      option is not received it defaults to a list of abbreviated month names in
      English

    * `:day_of_week_names` - a list of day names, if the option is not received
      it defaults to a list of day names in English

    * `:abbreviated_day_of_week_names` - a list of abbreviated day names, if the
      option is not received it defaults to a list of abbreviated day names in
      English

    * `:preferred_time` - a string for the preferred format to show times,
      it can't contain the `%X` format and defaults to `"%H:%M:%S"`
      if the option is not received

    * `:am_pm_names` - a keyword list with the names of the period of the day,
      defaults to `[am: "am", pm: "pm"]`.

  ## Examples
  ```elixir
      iex> Datix.strptime("2021/01/10", "%Y/%m/%d")
      {:ok, %{day: 10, month: 1, year: 2021}}

      iex> Datix.strptime("21/01/10", "%y/%m/%d")
      {:ok, %{day: 10, month: 1, year_2_digit: 21}}

      iex> Datix.strptime("13/14/15", "%H/%M/%S")
      {:ok, %{hour: 13, minute: 14, second: 15}}

      iex> Datix.strptime("1 PM", "%-I %p")
      {:ok, %{am_pm: :pm, hour_12: 1}}

      iex> Datix.strptime("Tuesday", "%A")
      {:ok, %{day_of_week: 2}}

      iex> Datix.strptime("Tue", "%a")
      {:ok, %{day_of_week: 2}}

      iex> Datix.strptime("Di", "%a",
      ...>   abbreviated_day_of_week_names: ~w(Mo Di Mi Do Fr Sa So))
      {:ok, %{day_of_week: 2}}
  ```
  """
  @spec strptime(String.t(), String.t(), keyword()) ::
          {:ok, Datix.t()}
          | {:error, :invalid_input}
          | {:error, {:parse_error, expected: String.t(), got: String.t()}}
          | {:error, {:conflict, [expected: term(), got: term(), modifier: String.t()]}}
          | {:error, {:invalid_string, [modifier: String.t()]}}
          | {:error, {:invalid_integer, [modifier: String.t()]}}
          | {:error, {:invalid_modifier, [modifier: String.t()]}}
  def strptime(date_time_str, format_str, opts \\ []) when is_binary(format_str) do
    with {:ok, options} <- options(opts) do
      case parse(format_str, date_time_str, options, %{}) do
        {:ok, result, ""} -> {:ok, result}
        {:ok, _result, _rest} -> {:error, :invalid_input}
        error -> error
      end
    end
  end

  @doc """
  Parses a date-time string according to the given `format`, erroring out for
  invalid arguments.
  """
  @spec strptime!(String.t(), String.t(), keyword()) :: Datix.t()
  def strptime!(date_time_str, format_str, opts \\ []) do
    case strptime(date_time_str, format_str, opts) do
      {:ok, data} ->
        data

      {:error, :invalid_input} ->
        raise ArgumentError, "invalid input"

      {:error, {:parse_error, expected: exp, got: got}} ->
        raise ArgumentError, "parse error: expected #{inspect(exp)}, got #{inspect(got)}"

      {:error, {:conflict, [expected: exp, got: got, modifier: mod]}} ->
        raise ArgumentError, "expected #{inspect(exp)}, got #{inspect(got)} for #{mod}"

      {:error, {:invalid_string, [modifier: mod]}} ->
        raise ArgumentError, "invalid string for #{mod}"

      {:error, {:invalid_integer, [modifier: mod]}} ->
        raise ArgumentError, "invalid integer for #{mod}"

      {:error, {:invalid_modifier, [modifier: mod]}} ->
        raise ArgumentError, "invalid format: #{mod}"
    end
  end

  @doc false
  @spec calendar(keyword()) :: module()
  def calendar(opts), do: Keyword.get(opts, :calendar, Calendar.ISO)

  @doc false
  def assume(data, Date) do
    case Map.has_key?(data, :year) || Map.has_key?(data, :year_2_digit) do
      true -> Map.merge(%{month: 1, day: 1}, data)
      false -> Map.merge(%{year: 0, month: 1, day: 1}, data)
    end
  end

  def assume(data, Time) do
    case Map.has_key?(data, :hour) || Map.has_key?(data, :hour_12) do
      true -> Map.merge(%{minute: 0, second: 0, microsecond: {0, 0}}, data)
      false -> Map.merge(%{hour: 0, minute: 0, second: 0, microsecond: {0, 0}}, data)
    end
  end

  defp parse("", date_time_rest, _opts, acc), do: {:ok, acc, date_time_rest}

  defp parse(_format_str, "", _opts, _acc), do: {:error, :invalid_input}

  defp parse("%" <> format_rest, date_time_str, opts, acc) do
    with {:ok, modifier, new_format_rest} <- parse_modifier(format_rest),
         {:ok, new_acc, date_time_rest} <- parse_date_time(modifier, date_time_str, opts, acc) do
      parse(new_format_rest, date_time_rest, opts, new_acc)
    end
  end

  defp parse(<<char, format_rest::binary>>, <<char, date_time_rest::binary>>, opts, acc) do
    parse(format_rest, date_time_rest, opts, acc)
  end

  defp parse(<<expected, _format_rest::binary>>, <<got, _date_time_rest::binary>>, _opts, _acc) do
    {:error, {:parse_error, expected: to_string([expected]), got: to_string([got])}}
  end

  defp parse_modifier(format_str, padding \\ nil, with \\ nil)

  defp parse_modifier("-" <> format_rest, _padding, nil = width) do
    parse_modifier(format_rest, "", width)
  end

  defp parse_modifier("_" <> format_rest, _padding, nil = width) do
    parse_modifier(format_rest, ?\s, width)
  end

  defp parse_modifier("0" <> format_rest, _padding, nil = width) do
    parse_modifier(format_rest, ?0, width)
  end

  defp parse_modifier(<<digit, format_rest::binary>>, padding, width) when digit in ?0..?9 do
    parse_modifier(format_rest, padding, (width || 0) * 10 + (digit - ?0))
  end

  defp parse_modifier(<<format, format_rest::binary>>, padding, width) do
    {
      :ok,
      {format, padding || default_padding(format), width || default_width(format)},
      format_rest
    }
  end

  defp parse_date_time({format, padding, _width} = modifier, date_time_str, opts, acc)
       when format in 'aAbBpP' do
    with {:ok, value, rest} <- parse_string(date_time_str, padding, enumeration(format, opts)),
         {:ok, new_acc} <- put(acc, format, value) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time({format, padding, width} = modifier, date_time_str, _opts, acc)
       when format in 'dHIjmMqSu' do
    with {:ok, value, rest} <- parse_pos_integer(date_time_str, padding, width),
         {:ok, new_acc} <- put(acc, format, value) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time({format, padding, width} = modifier, date_time_str, _opts, acc)
       when format in 'yY' do
    with {:ok, value, rest} <- parse_integer(date_time_str, padding, width),
         {:ok, new_acc} <- put(acc, format, value) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time({?f, _padding, _width} = modifier, date_time_str, _opts, acc) do
    with {:ok, microsecond, rest} <- parse_pos_integer(date_time_str),
         {:ok, new_acc} <- put(acc, :microsecond, microsecond) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time({?z, padding, width} = modifier, date_time_str, _opts, acc) do
    with {:ok, zone_offset, rest} <- parse_signed_integer(date_time_str, padding, width),
         {:ok, new_acc} <- put(acc, :zone_offset, zone_offset(zone_offset)) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time({?Z, padding, _width} = modifier, date_time_str, _opts, acc) do
    with {:ok, zone_abbr, rest} <- parse_upcase_string(date_time_str, padding),
         {:ok, new_acc} <- put(acc, :zone_abbr, zone_abbr) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time(
         {format, _padding, _width} = modifier,
         _date_time_str,
         %{preferred: format},
         _acc
       ) do
    {:error, {:cycle, modifier_to_string(modifier)}}
  end

  defp parse_date_time({format, _padding, _width}, date_time_str, opts, acc)
       when format in 'cxX' do
    parse(preferred_format(format, opts), date_time_str, Map.put(opts, :preferred, format), acc)
  end

  defp parse_date_time({?%, _padding, _width}, "%" <> date_time_rest, _opts, acc) do
    {:ok, acc, date_time_rest}
  end

  defp parse_date_time({?%, _padding, _width}, _date_time_rest, _opts, _acc) do
    {:error, {:invalid_string, modifier: "%%"}}
  end

  defp parse_date_time(modifier, _date_time_str, _opts, _acc) do
    {:error, {:invalid_modifier, modifier: modifier_to_string(modifier)}}
  end

  defp parse_integer(str, padding, width, int \\ nil)

  defp parse_integer("-" <> int_str, padding, width, nil) do
    with {:ok, int, rest} <- parse_pos_integer(int_str, padding, width, 0) do
      {:ok, int * -1, rest}
    end
  end

  defp parse_integer(int_str, padding, width, nil) do
    parse_pos_integer(int_str, padding, width, nil)
  end

  defp parse_pos_integer(str, int \\ nil)

  defp parse_pos_integer(<<digit, rest::binary>>, int) when digit in ?0..?9 do
    parse_pos_integer(rest, (int || 0) * 10 + (digit - ?0))
  end

  defp parse_pos_integer(_rest, nil), do: {:error, :invalid_integer}

  defp parse_pos_integer(rest, int), do: {:ok, int, rest}

  defp parse_pos_integer(str, padding, width, int \\ nil)

  defp parse_pos_integer(rest, _padding, width, nil) when width < 1, do: {:ok, 0, rest}
  defp parse_pos_integer(rest, _padding, width, int) when width < 1, do: {:ok, int, rest}

  defp parse_pos_integer(<<digit, rest::binary>>, "" = padding, width, int)
       when digit in ?0..?9 do
    parse_pos_integer(rest, padding, width - 1, (int || 0) * 10 + (digit - ?0))
  end

  defp parse_pos_integer(rest, "" = _padding, _width, int), do: {:ok, int, rest}

  defp parse_pos_integer(<<padding, rest::binary>>, padding, width, nil = acc) do
    parse_pos_integer(rest, padding, width - 1, acc)
  end

  defp parse_pos_integer(<<digit, rest::binary>>, padding, width, int) when digit in ?0..?9 do
    parse_pos_integer(rest, padding, width - 1, (int || 0) * 10 + (digit - ?0))
  end

  defp parse_pos_integer(_str, _padding, _width, _int), do: {:error, :invalid_integer}

  defp parse_signed_integer("-" <> str, padding, width) do
    with {:ok, value, rest} <- parse_pos_integer(str, padding, width) do
      {:ok, value * -1, rest}
    end
  end

  defp parse_signed_integer("+" <> str, padding, width),
    do: parse_pos_integer(str, padding, width)

  defp parse_signed_integer(_str, _padding, _width), do: {:error, :invalid_integer}

  defp parse_string(str, padding, list, pos \\ 0)

  defp parse_string(<<padding, rest::binary>>, padding, list, 0 = pos) do
    parse_string(rest, padding, list, pos)
  end

  defp parse_string(_str, _padding, [], _pos), do: {:error, :invalid_string}

  defp parse_string(str, padding, [item | list], pos) do
    case String.starts_with?(str, item) do
      false -> parse_string(str, padding, list, pos + 1)
      true -> {:ok, pos + 1, String.slice(str, String.length(item)..-1)}
    end
  end

  defp parse_upcase_string(str, padding, acc \\ [])

  defp parse_upcase_string(<<padding, rest::binary>>, padding, [] = acc) do
    parse_upcase_string(rest, padding, acc)
  end

  defp parse_upcase_string(<<char, rest::binary>>, padding, acc) when char in ?A..?Z do
    parse_upcase_string(rest, padding, [char | acc])
  end

  defp parse_upcase_string(_rest, _padding, []), do: {:error, :invalid_string}

  defp parse_upcase_string(rest, _padding, acc) do
    {:ok, acc |> Enum.reverse() |> IO.iodata_to_binary(), rest}
  end

  defp modifier_to_string({format, padding, width}) do
    IO.iodata_to_binary([
      "%",
      padding_to_string(padding, format),
      width_to_string(width, format),
      format
    ])
  end

  defp padding_to_string(padding, format) do
    case padding == default_padding(format) do
      true -> ""
      false -> padding
    end
  end

  defp width_to_string(width, format) do
    case width == default_width(format) do
      true -> ""
      false -> to_string(width)
    end
  end

  defp error({:error, {:conflict, {expected, got}}}, modifier) do
    {:error, {:conflict, expected: expected, got: got, modifier: modifier_to_string(modifier)}}
  end

  defp error({:error, reason}, modifier) do
    {:error, {reason, modifier: modifier_to_string(modifier)}}
  end

  defp zone_offset(value) do
    hour = div(value, 100)
    minute = rem(value, 100)
    hour * 3600 + minute * 60
  end

  defp default_padding(format) when format in 'aAbBpPZ', do: ?\s
  defp default_padding(_format), do: ?0

  defp default_width(format) when format in 'Yz', do: 4
  defp default_width(?j), do: 3
  defp default_width(format) when format in 'dHImMSy', do: 2
  defp default_width(format) when format in 'qu', do: 1
  defp default_width(_format), do: 0

  defp put(acc, key, value) when is_atom(key) do
    case Map.fetch(acc, key) do
      {:ok, ^value} -> {:ok, acc}
      {:ok, expected} -> {:error, {:conflict, {expected, value}}}
      :error -> {:ok, Map.put(acc, key, value)}
    end
  end

  defp put(acc, format, 1) when format in 'pP', do: put(acc, :am_pm, :am)
  defp put(acc, format, 2) when format in 'pP', do: put(acc, :am_pm, :pm)
  defp put(acc, format, value), do: put(acc, key(format), value)

  defp key(format) when format in 'aA', do: :day_of_week
  defp key(format) when format in 'bB', do: :month
  defp key(?d), do: :day
  defp key(?H), do: :hour
  defp key(?I), do: :hour_12
  defp key(?j), do: :day_of_year
  defp key(?m), do: :month
  defp key(?M), do: :minute
  defp key(?y), do: :year_2_digit
  defp key(?Y), do: :year
  defp key(?q), do: :quarter
  defp key(?S), do: :second
  defp key(?u), do: :day_of_week

  defp preferred_format(?c, opts), do: opts.preferred_datetime
  defp preferred_format(?x, opts), do: opts.preferred_date
  defp preferred_format(?X, opts), do: opts.preferred_time

  defp enumeration(?a, opts), do: opts.abbreviated_day_of_week_names
  defp enumeration(?A, opts), do: opts.day_of_week_names
  defp enumeration(?b, opts), do: opts.abbreviated_month_names
  defp enumeration(?B, opts), do: opts.month_names

  defp enumeration(?p, opts),
    do: [String.upcase(opts.am_pm_names[:am]), String.upcase(opts.am_pm_names[:pm])]

  defp enumeration(?P, opts),
    do: [String.downcase(opts.am_pm_names[:am]), String.downcase(opts.am_pm_names[:pm])]

  defp options(opts) do
    defaults = %{
      preferred_date: "%Y-%m-%d",
      preferred_time: "%H:%M:%S",
      preferred_datetime: "%Y-%m-%d %H:%M:%S",
      am_pm_names: [am: "am", pm: "pm"],
      month_names: [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ],
      day_of_week_names: [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ],
      abbreviated_month_names: [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ],
      abbreviated_day_of_week_names: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    opts
    |> Keyword.delete(:calendar)
    |> Enum.reduce_while({:ok, defaults}, fn {key, value}, {:ok, acc} ->
      case Map.has_key?(acc, key) do
        true -> {:cont, {:ok, %{acc | key => value}}}
        false -> {:halt, {:error, {:unknown, option: key}}}
      end
    end)
  end
end
