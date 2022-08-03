defmodule Datix.Date do
  @moduledoc """
  A `Date` parser using `Calendar.strftime/3` format strings.
  """

  alias Datix.{OptionError, ValidationError}

  @doc """
  Parses a date string according to the given `format`.

  See the `Calendar.strftime/3` documentation for how to specify a format-string.

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

    * `:pivot_year` - a 2-digit year that represents the *pivot year* to use when
      `%y` is used. `%y` represents a 2-digit year, but Datix doesn't assume anything
      about which *century* such year refers to. For this reason, the `:pivot_year`
      option is required whenever `%y` is present in the format string; if not
      present, this function returns `{:error, %Datix.OptionError{}}`.
      For example, if `pivot_year: 65`, then the 2-digit year `64` and lower will
      refer to the current century (`2064` and so on at the time of writing this),
      while the 2-digit year `65` and higher will refer to the previous century
      (`1965` and so on).

  Missing values will be set to minimum.

  ## Examples

      iex> Datix.Date.parse("2022-05-11", "%x")
      {:ok, ~D[2022-05-11]}

      iex> Datix.Date.parse("2021/01/10", "%Y/%m/%d")
      {:ok, ~D[2021-01-10]}

      iex> format = Datix.compile!("%Y/%m/%d")
      iex> Datix.Date.parse("2021/01/10", format)
      {:ok, ~D[2021-01-10]}

      iex> Datix.Date.parse("2021/01/10", "%x", preferred_date: "%Y/%m/%d")
      {:ok, ~D[2021-01-10]}

      iex> Datix.Date.parse("18", "%y", pivot_year: 50)
      {:ok, ~D[2018-01-01]}

      iex> Datix.Date.parse("18", "%y", pivot_year: 15)
      {:ok, ~D[1918-01-01]}

      iex> Datix.Date.parse("18", "%y")
      {:error, %Datix.OptionError{reason: :missing, option: :pivot_year}}

      iex> Datix.Date.parse("", "")
      {:ok, ~D[0000-01-01]}

      iex> Datix.Date.parse("1736/13/03", "%Y/%m/%d", calendar: Coptic)
      {:ok, ~D[1736-13-03 Cldr.Calendar.Coptic]}

      iex> Datix.Date.parse("Mi, 1.4.2020", "%a, %-d.%-m.%Y",
      ...>   abbreviated_day_of_week_names: ~w(Mo Di Mi Do Fr Sa So))
      {:ok, ~D[2020-04-01]}

      iex> Datix.Date.parse("Fr, 1.4.2020", "%a, %-d.%-m.%Y",
      ...>   abbreviated_day_of_week_names: ~w(Mo Di Mi Do Fr Sa So))
      {:error, %Datix.ValidationError{reason: :invalid_date, module: Datix.Date}}

  """
  @spec parse(String.t(), String.t() | Datix.compiled(), list()) ::
          {:ok, Date.t()}
          | {:error,
             Datix.FormatStringError.t()
             | Datix.ParseError.t()
             | Datix.ValidationError.t()
             | Datix.OptionError.t()}
  def parse(date_str, format, opts \\ []) do
    with {:ok, data} <- Datix.strptime(date_str, format, opts) do
      new(data, opts)
    end
  end

  @doc """
  Parses a date string according to the given `format`, erroring out for
  invalid arguments.
  """
  @spec parse!(String.t(), String.t() | Datix.compiled(), list()) :: Date.t()
  def parse!(date_str, format, opts \\ []) do
    case parse(date_str, format, opts) do
      {:ok, date} -> date
      {:error, error} when is_exception(error) -> raise error
    end
  end

  @doc false
  def new(%{year: year, month: month, day: day} = data, opts) do
    case Date.new(year, month, day, Datix.calendar(opts)) do
      {:ok, date} ->
        validate(date, data)

      {:error, :invalid_date} ->
        {:error, %ValidationError{reason: :invalid_date, module: __MODULE__}}
    end
  end

  def new(%{year_2_digit: year, month: _month, day: _day} = data, opts) do
    case Keyword.fetch(opts, :pivot_year) do
      {:ok, pivot_year} ->
        current_century = div(DateTime.utc_now(Datix.calendar(opts)).year, 100)

        year =
          cond do
            year < 0 -> year
            year <= pivot_year -> current_century * 100 + year
            true -> (current_century - 1) * 100 + year
          end

        data
        |> Map.put(:year, year)
        |> Map.delete(:year_2_digit)
        |> new(opts)

      :error ->
        {:error, %OptionError{reason: :missing, option: :pivot_year}}
    end
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
      _day_of_week -> {:error, %ValidationError{reason: :invalid_date, module: __MODULE__}}
    end
  end

  defp validate(date, [{:day_of_year, day_of_jear} | rest]) do
    case Date.day_of_year(date) do
      ^day_of_jear -> validate(date, rest)
      _day_of_jear -> {:error, %ValidationError{reason: :invalid_date, module: __MODULE__}}
    end
  end

  defp validate(date, [{:quarter, quarter} | rest]) do
    case Date.quarter_of_year(date) do
      ^quarter -> validate(date, rest)
      _quarter -> {:error, %ValidationError{reason: :invalid_date, module: __MODULE__}}
    end
  end
end
