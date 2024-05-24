defmodule Datix do
  @moduledoc """
  A date-time parser using `Calendar.strftime/3` format strings.
  """

  alias Datix.FormatStringError
  alias Datix.OptionError
  alias Datix.ParseError

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

  @typedoc """
  An **opaque** type representing a compiled format.

  The struct representation is internal and could change in the future without notice.
  """
  @typedoc since: "0.2.0"
  @opaque compiled :: %__MODULE__{
            format: [
              {:exact, binary()}
              | {:modifier, {char(), padder :: char(), width :: non_neg_integer()}}
            ],
            original: String.t()
          }

  @doc false
  defstruct format: [], original: nil

  defimpl Inspect do
    def inspect(%@for{original: original}, opts) do
      Inspect.Algebra.concat(["Datix.compile!(", Inspect.BitString.inspect(original, opts), ")"])
    end
  end

  @doc """
  Parses a date-time string according to the given `format`.

  See the `Calendar.strftime/3` documentation for how to specify a format string.

  `format` can be a format string or, since v0.2.0 of the library,
  a **compiled format** as returned by `compile/1`.

  If parsing is successful, this function returns `{:ok, datix}` where `datix` is
  a map of type `t:t/0`. If you are looking for functions that return Elixir
  structs (such as `DateTime` and similar), see `Datix.DateTime`, `Datix.Date`,
  `Datix.Time`, and `Datix.NaiveDateTime`.

  If there's an error, this function returns `{:error, error}` where error
  is an *exception struct*. You can raise it manually with `raise/1`.

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

      iex> compiled = Datix.compile!("%Y/%m/%d")
      iex> Datix.strptime("2021/01/10", compiled)
      {:ok, %{day: 10, month: 1, year: 2021}}

      iex> Datix.strptime("irrelevant", "%l")
      {:error, %Datix.FormatStringError{reason: {:invalid_modifier, "%l"}}}

  """
  @spec strptime(String.t(), String.t() | compiled(), keyword()) ::
          {:ok, Datix.t()} | {:error, ParseError.t() | FormatStringError.t() | OptionError.t()}
  def strptime(date_time_str, format, opts \\ [])

  def strptime(date_time_str, %__MODULE__{format: format}, opts) do
    with {:ok, options} <- options(opts) do
      case parse(format, date_time_str, options, %{}) do
        {:ok, result, ""} -> {:ok, result}
        {:ok, _result, _rest} -> {:error, %ParseError{reason: :invalid_input}}
        error -> error
      end
    end
  end

  def strptime(date_time_str, format_str, opts) when is_binary(format_str) do
    with {:ok, compiled} <- compile(format_str) do
      strptime(date_time_str, compiled, opts)
    end
  end

  @doc """
  Parses a date-time string according to the given `format`, erroring out for
  invalid arguments.
  """
  @spec strptime!(String.t(), String.t() | compiled(), keyword()) :: Datix.t()
  def strptime!(date_time_str, format, opts \\ []) do
    case strptime(date_time_str, format, opts) do
      {:ok, data} -> data
      {:error, reason} when is_exception(reason) -> raise reason
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

  @doc """
  Compiles the given `format` string.

  If the `format` string is a valid format string, then this function returns
  `{:ok, compiled}`. `compiled` is a term that represents a compiled format (its internal
  representation is private). You can pass a `t:compiled/0` term to `strptime/3` and
  such.

  If the `format` string is invalid, this function returns `{:error, reason}`, where
  `reason` is an *exception struct*.

  You can use this function for two reasons:

    * You have the same format string that you want to compile once and then use
      to parse over and over

    * You want to *validate* a format string

  """
  @doc since: "0.2.0"
  @spec compile(String.t()) :: {:ok, compiled()} | {:error, FormatStringError.t()}
  def compile(format) when is_binary(format) do
    case compile(format, _acc = []) do
      {:ok, compiled_format} -> {:ok, %__MODULE__{format: compiled_format, original: format}}
      {:error, reason} when is_exception(reason) -> {:error, reason}
    end
  end

  @doc """
  Like `compile/1`, but returns the compiled struct directly or raises in case of errors.

  ## Examples

      iex> Datix.compile!("%Y-%m-%d")
      Datix.compile!("%Y-%m-%d")

      iex> Datix.compile!("%l")
      ** (Datix.FormatStringError) invalid format string because of invalid modifier: %l

  """
  @doc since: "0.2.0"
  @spec compile!(String.t()) :: compiled()
  def compile!(format) do
    case compile(format) do
      {:ok, compiled} -> compiled
      {:error, reason} when is_exception(reason) -> raise reason
    end
  end

  defp compile("", acc), do: {:ok, Enum.reverse(acc)}

  defp compile("%" <> rest, acc) do
    with {:ok, modifier, rest} <- compile_modifier(rest, nil, nil) do
      compile(rest, [{:modifier, modifier} | acc])
    end
  end

  defp compile(<<_, _::binary>> = rest, acc) do
    {exact, rest} = take_until_modifier(rest, _acc = "")
    compile(rest, [{:exact, exact} | acc])
  end

  defp take_until_modifier(<<>> = rest, acc), do: {acc, rest}
  defp take_until_modifier(<<?%, _::binary>> = rest, acc), do: {acc, rest}

  defp take_until_modifier(<<char, rest::binary>>, acc),
    do: take_until_modifier(rest, <<acc::binary, char>>)

  defp compile_modifier("-" <> rest, _padding, nil = width) do
    compile_modifier(rest, _padding = "", width)
  end

  defp compile_modifier("_" <> rest, _padding, nil = width) do
    compile_modifier(rest, _padding = ?\s, width)
  end

  defp compile_modifier("0" <> rest, _padding, nil = width) do
    compile_modifier(rest, _padding = ?0, width)
  end

  defp compile_modifier(<<digit, rest::binary>>, padding, width) when digit in ?0..?9 do
    compile_modifier(rest, padding, (width || 0) * 10 + (digit - ?0))
  end

  defp compile_modifier(<<format, rest::binary>>, padding, width) do
    modifier = {format, padding || default_padding(format), width || default_width(format)}

    if format in ~c"aAbBpPcxXdHIjmMqSufzZyY%" do
      {:ok, modifier, rest}
    else
      {:error, %FormatStringError{reason: {:invalid_modifier, modifier_to_string(modifier)}}}
    end
  end

  defp parse([], date_time_rest, _opts, acc), do: {:ok, acc, date_time_rest}

  defp parse(_format, "", _opts, _acc), do: {:error, %ParseError{reason: :invalid_input}}

  defp parse([{:modifier, modifier} | format_rest], date_time_str, opts, acc) do
    with {:ok, new_acc, date_time_rest} <- parse_date_time(modifier, date_time_str, opts, acc) do
      parse(format_rest, date_time_rest, opts, new_acc)
    end
  end

  defp parse([{:exact, exact} | format_rest], date_time_str, opts, acc) do
    expected_size = byte_size(exact)

    case date_time_str do
      <<got::size(expected_size)-binary, date_time_rest::binary>> when got == exact ->
        parse(format_rest, date_time_rest, opts, acc)

      _other ->
        {:error, %ParseError{reason: {:expected_exact, exact, _got = date_time_str}}}
    end
  end

  defp parse_date_time({format, padding, _width} = modifier, date_time_str, opts, acc)
       when format in ~c"aAbBpP" do
    with {:ok, value, rest} <- parse_string(date_time_str, padding, enumeration(format, opts)),
         {:ok, new_acc} <- put(acc, format, value) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time({format, padding, width} = modifier, date_time_str, _opts, acc)
       when format in ~c"dHIjmMqSu" do
    with {:ok, value, rest} <-
           parse_pos_integer(date_time_str, padding, width, _exact_width? = false),
         {:ok, new_acc} <- put(acc, format, value) do
      {:ok, new_acc, rest}
    else
      error -> error(error, modifier)
    end
  end

  defp parse_date_time({format, padding, width} = modifier, date_time_str, _opts, acc)
       when format in ~c"yY" do
    exact_width? = format == ?Y

    with {:ok, value, rest} <- parse_integer(date_time_str, padding, width, exact_width?),
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
    with {:ok, zone_offset, rest} <-
           parse_signed_integer(date_time_str, padding, width, _exact_width? = true),
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
       when format in ~c"cxX" do
    {:ok, %__MODULE__{format: compiled_format}} = compile(preferred_format(format, opts))
    parse(compiled_format, date_time_str, Map.put(opts, :preferred, format), acc)
  end

  defp parse_date_time({?%, _padding, _width}, "%" <> date_time_rest, _opts, acc) do
    {:ok, acc, date_time_rest}
  end

  defp parse_date_time({?%, _padding, _width}, _date_time_rest, _opts, _acc) do
    {:error, %ParseError{reason: :invalid_string, modifier: "%%"}}
  end

  defp parse_date_time(modifier, _date_time_str, _opts, _acc) do
    {:error, %FormatStringError{reason: {:invalid_modifier, modifier_to_string(modifier)}}}
  end

  defp parse_integer(str, padding, width, exact_width?, int \\ nil)

  defp parse_integer("-" <> int_str, padding, width, exact_width?, nil) do
    with {:ok, int, rest} <- parse_pos_integer(int_str, padding, width, exact_width?, nil) do
      {:ok, int * -1, rest}
    end
  end

  defp parse_integer(int_str, padding, width, exact_width?, nil) do
    parse_pos_integer(int_str, padding, width, exact_width?, nil)
  end

  defp parse_pos_integer(str) do
    case Integer.parse(str) do
      {int, rest} -> {:ok, int, rest}
      :error -> {:error, %ParseError{reason: :invalid_integer}}
    end
  end

  defp parse_pos_integer(str, padding, max_width, exact_width?, int \\ nil)

  defp parse_pos_integer(rest, _padding, 0 = _width, _exact_width?, int) do
    {:ok, int || 0, rest}
  end

  defp parse_pos_integer(<<digit, rest::binary>>, "" = padding, width, exact_width?, int)
       when digit in ?0..?9 do
    parse_pos_integer(rest, padding, width - 1, exact_width?, (int || 0) * 10 + (digit - ?0))
  end

  defp parse_pos_integer(rest, "" = _padding, _width, _exact_width?, int), do: {:ok, int, rest}

  defp parse_pos_integer(<<padding, rest::binary>>, padding, width, exact_width?, nil = acc) do
    parse_pos_integer(rest, padding, width - 1, exact_width?, acc)
  end

  defp parse_pos_integer(<<digit, rest::binary>>, padding, width, exact_width?, int)
       when digit in ?0..?9 do
    parse_pos_integer(rest, padding, width - 1, exact_width?, (int || 0) * 10 + (digit - ?0))
  end

  # If no integer was parsed yet when we get to a non-digit, then there was no integer,
  # so we return an error.
  defp parse_pos_integer(_str, _padding, _width, _exact_width?, nil),
    do: {:error, %ParseError{reason: :invalid_integer}}

  # If an integer was parsed then we can return it even if we have some "width" left,
  # since the width represents the maximum width.
  defp parse_pos_integer(str, _padding, _width_left, false = _exact_width?, int),
    do: {:ok, int, str}

  defp parse_pos_integer(_str, _padding, _width_left, true = _exact_width?, _int),
    do: {:error, %ParseError{reason: :invalid_integer}}

  defp parse_signed_integer("-" <> str, padding, width, exact_width?) do
    with {:ok, value, rest} <- parse_pos_integer(str, padding, width, exact_width?) do
      {:ok, value * -1, rest}
    end
  end

  defp parse_signed_integer("+" <> str, padding, width, exact_width?),
    do: parse_pos_integer(str, padding, width, exact_width?)

  defp parse_signed_integer(_str, _padding, _width, _exact_width?),
    do: {:error, %ParseError{reason: :invalid_integer}}

  defp parse_string(str, padding, list, pos \\ 0)

  defp parse_string(<<padding, rest::binary>>, padding, list, 0 = pos) do
    parse_string(rest, padding, list, pos)
  end

  defp parse_string(_str, _padding, [], _pos), do: {:error, %ParseError{reason: :invalid_string}}

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

  defp parse_upcase_string(_rest, _padding, []),
    do: {:error, %ParseError{reason: :invalid_string}}

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

  defp error({:error, %ParseError{} = error}, modifier) do
    {:error, %ParseError{error | modifier: modifier_to_string(modifier)}}
  end

  defp zone_offset(value) do
    hour = div(value, 100)
    minute = rem(value, 100)
    hour * 3600 + minute * 60
  end

  defp default_padding(format) when format in ~c"aAbBpPZ", do: ?\s
  defp default_padding(_format), do: ?0

  defp default_width(format) when format in ~c"Yz", do: 4
  defp default_width(?j), do: 3
  defp default_width(format) when format in ~c"dHImMSy", do: 2
  defp default_width(format) when format in ~c"qu", do: 1
  defp default_width(_format), do: 0

  defp put(acc, key, value) when is_atom(key) do
    case Map.fetch(acc, key) do
      {:ok, ^value} -> {:ok, acc}
      {:ok, expected} -> {:error, %ParseError{reason: {:conflict, expected, value}}}
      :error -> {:ok, Map.put(acc, key, value)}
    end
  end

  defp put(acc, format, 1) when format in ~c"pP", do: put(acc, :am_pm, :am)
  defp put(acc, format, 2) when format in ~c"pP", do: put(acc, :am_pm, :pm)
  defp put(acc, format, value), do: put(acc, key(format), value)

  defp key(format) when format in ~c"aA", do: :day_of_week
  defp key(format) when format in ~c"bB", do: :month
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

    extra_allowed_keys = [:pivot_year, :time_zone]

    opts
    |> Keyword.delete(:calendar)
    |> Enum.reduce_while({:ok, defaults}, fn {key, value}, {:ok, acc} ->
      cond do
        Map.has_key?(acc, key) -> {:cont, {:ok, %{acc | key => value}}}
        key in extra_allowed_keys -> {:cont, {:ok, acc}}
        true -> {:halt, {:error, %OptionError{reason: :unknown, option: key}}}
      end
    end)
  end
end
