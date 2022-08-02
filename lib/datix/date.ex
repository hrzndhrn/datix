defmodule Datix.Date do
  @moduledoc """
  A `Date` parser using `Calendar.strftime` format string.
  """

  @doc """
  Parses a date string according to the given `format`.

  See the `Calendar.strftime` documentation for how to specify a format-string.

  ## Options

    * `:calendar` - the calendar to build the `Date`, defaults to `Calendar.ISO`

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

  Missing values will be set to minimum.

  ## Examples

      iex> Datix.Date.parse("2022-05-11", "%x")
      {:ok, ~D[2022-05-11]}

      iex> Datix.Date.parse("2021/01/10", "%Y/%m/%d")
      {:ok, ~D[2021-01-10]}

      iex> Datix.Date.parse("2021/01/10", "%x", preferred_date: "%Y/%m/%d")
      {:ok, ~D[2021-01-10]}

      iex> Datix.Date.parse("18", "%y")
      {:ok, ~D[0018-01-01]}

      iex> Datix.Date.parse("", "")
      {:ok, ~D[0000-01-01]}

      iex> Datix.Date.parse("1736/13/03", "%Y/%m/%d", calendar: Coptic)
      {:ok, ~D[1736-13-03 Cldr.Calendar.Coptic]}

      iex> Datix.Date.parse("Mi, 1.4.2020", "%a, %-d.%-m.%Y",
      ...>   abbreviated_day_of_week_names: ~w(Mo Di Mi Do Fr Sa So))
      {:ok, ~D[2020-04-01]}

      iex> Datix.Date.parse("Fr, 1.4.2020", "%a, %-d.%-m.%Y",
      ...>   abbreviated_day_of_week_names: ~w(Mo Di Mi Do Fr Sa So))
      {:error, :invalid_date}
  """
  @spec parse(String.t(), String.t(), list()) ::
          {:ok, Date.t()}
          | {:error, :invalid_date}
          | {:error, :invalid_input}
          | {:error, {:parse_error, expected: String.t(), got: String.t()}}
          | {:error, {:conflict, [expected: term(), got: term(), modifier: String.t()]}}
          | {:error, {:invalid_string, [modifier: String.t()]}}
          | {:error, {:invalid_integer, [modifier: String.t()]}}
          | {:error, {:invalid_modifier, [modifier: String.t()]}}
  def parse(date_str, format_str, opts \\ []) do
    with {:ok, data} <- Datix.strptime(date_str, format_str, opts) do
      new(data, opts)
    end
  end

  @doc """
  Parses a date string according to the given `format`, erroring out for
  invalid arguments.
  """
  @spec parse!(String.t(), String.t(), list()) :: Date.t()
  def parse!(date_str, format_str, opts \\ []) do
    date_str
    |> Datix.strptime!(format_str, opts)
    |> new(opts)
    |> case do
      {:ok, date} ->
        date

      {:error, reason} ->
        raise ArgumentError, "cannot build date, reason: #{inspect(reason)}"
    end
  end

  @doc false
  def new(%{year: year, month: month, day: day} = data, opts) do
    with {:ok, date} <- Date.new(year, month, day, Datix.calendar(opts)) do
      validate(date, data)
    end
  end

  def new(%{year_2_digit: year, month: _month, day: _day} = data, opts) do
    data
    |> Map.put(:year, year)
    |> Map.delete(:year_2_digit)
    |> new(opts)
  end

  def new(data, opts), do: data |> Datix.assume(Date) |> new(opts)

  defp validate(date, data) when is_map(data) do
    validate(
      date,
      data
      |> Map.drop([
        :am_pm,
        :day,
        :hour,
        :hour_12,
        :microsecond,
        :minute,
        :month,
        :second,
        :year,
        :zone_abbr,
        :zone_offset
      ])
      |> Enum.to_list()
    )
  end

  defp validate(date, []), do: {:ok, date}

  defp validate(date, [{:day_of_week, day_of_week} | rest]) do
    case Date.day_of_week(date) do
      ^day_of_week -> validate(date, rest)
      _day_of_week -> {:error, :invalid_date}
    end
  end

  defp validate(date, [{:day_of_year, day_of_jear} | rest]) do
    case Date.day_of_year(date) do
      ^day_of_jear -> validate(date, rest)
      _day_of_jear -> {:error, :invalid_date}
    end
  end

  defp validate(date, [{:quarter, quarter} | rest]) do
    case Date.quarter_of_year(date) do
      ^quarter -> validate(date, rest)
      _quarter -> {:error, :invalid_date}
    end
  end
end
