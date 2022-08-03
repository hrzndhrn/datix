defmodule Datix.DateTime do
  @moduledoc """
  A `DateTime` parser using `Calendar.strftime/3` format string.
  """

  alias Datix.ValidationError

  @doc """
  Parses a datetime string into a `DateTime` according to the given `format`.

  See the `Calendar.strftime/3` documentation for how to specify a format string.

  When the format string contains an offset (`%z`) or a timezone abbreviation (`%Z`),
  then the `:time_zone` option is required. See below for more information on the option.

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

    * `:preferred_time` - a string for the preferred format to show times,
      it can't contain the `%X` format and defaults to `"%H:%M:%S"`
      if the option is not received

    * `:am_pm_names` - a keyword list with the names of the period of the day,
      defaults to `[am: "am", pm: "pm"]`.

    * `:pivot_year` - (since v0.2.0) a 2-digit year that represents the *pivot year* to use when
      `%y` is used. `%y` represents a 2-digit year, but Datix doesn't assume anything
      about which *century* such year refers to. For this reason, the `:pivot_year`
      option is required whenever `%y` is present in the format string; if not
      present, this function returns `{:error, :missing_pivot_year_option}`.
      For example, if `pivot_year: 65`, then the 2-digit year `64` and lower will
      refer to the current century (`2064` and so on at the time of writing this),
      while the 2-digit year `65` and higher will refer to the previous century
      (`1965` and so on).

    * `:time_zone` - (since v0.3.0) TODO

  ## Examples

      iex> Datix.DateTime.parse("2021/01/10 12:14:24", "%Y/%m/%d %H:%M:%S")
      {:ok, ~U[2021-01-10 12:14:24Z]}

      iex> format = Datix.compile!("%Y/%m/%d %H:%M:%S")
      iex> Datix.DateTime.parse("2021/01/10 12:14:24", format)
      {:ok, ~U[2021-01-10 12:14:24Z]}

      iex> Datix.DateTime.parse("2018/06/27 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z")
      {:error, %Datix.ValidationError{module: Datix.DateTime, reason: {:unknown_timezone_abbr, "CEST"}}}


  If you need to parse non-UTC datetimes, you'll have to pass the `:time_zone` option.

      tz_fun = fn naive_datetime, abbr, offset ->
        {:ok, naive_datetime |> DateTime.from_naive!(convert_abbr(abbr)) |> DateTime.add(-offset)}
      end

      Datix.DateTime.parse("2018/06/27 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z", time_zone: tz_fun)

  """
  @spec parse(String.t(), String.t() | Datix.compiled(), list()) ::
          {:ok, DateTime.t()}
          | {:error,
             Datix.FormatStringError.t()
             | Datix.ParseError.t()
             | Datix.ValidationError.t()
             | Datix.OptionError.t()}
  def parse(datetime_str, format, opts \\ []) do
    with {:ok, data} <- Datix.strptime(datetime_str, format, opts) do
      new(data, opts)
    end
  end

  @doc """
  Parses a datetime string according to the given `format`, erroring out for
  invalid arguments.

  This function is just defined for UTC datetimes.

  ## Options

  Accepts the same options as listed for `parse/3`.

  ## Examples

      iex> Datix.DateTime.parse!("2018/06/27 11:23:55 UTC+0000", "%Y/%m/%d %H:%M:%S %Z%z")
      ~U[2018-06-27 11:23:55Z]

      iex> format = Datix.compile!("%Y/%m/%d %H:%M:%S %Z%z")
      iex> Datix.DateTime.parse!("2018/06/27 11:23:55 UTC+0000", format)
      ~U[2018-06-27 11:23:55Z]

      iex> Datix.DateTime.parse!("2018/06/27 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z")
      ** (Datix.ValidationError) unknown timezone abbreviation: CEST

  """
  @spec parse!(String.t(), String.t() | Datix.compiled(), list()) :: DateTime.t()
  def parse!(datetime_str, format, opts \\ []) do
    case parse(datetime_str, format, opts) do
      {:ok, datetime} -> datetime
      {:error, error} when is_exception(error) -> raise error
    end
  end

  @doc false
  def new(data, opts) do
    with {:ok, date} <- Datix.Date.new(data, opts),
         {:ok, time} <- Datix.Time.new(data, opts) do
      time_zone_fun = Keyword.get(opts, :time_zone, &default_time_zone_fun/3)
      naive_datetime = NaiveDateTime.new!(date, time)
      time_zone_fun.(naive_datetime, Map.get(data, :zone_abbr), Map.get(data, :zone_offset))
    end
  end

  defp default_time_zone_fun(naive_datetime, zone_abbr, offset) do
    case {zone_abbr || "UTC", offset || 0} do
      {"UTC", 0} ->
        {:ok, DateTime.from_naive!(naive_datetime, "Etc/UTC")}

      {"UTC", offset} when is_integer(offset) and offset != 0 ->
        {:ok, naive_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.add(-offset)}

      {abbr, _offset} ->
        {:error, %ValidationError{reason: {:unknown_timezone_abbr, abbr}, module: Datix.DateTime}}
    end
  end
end
