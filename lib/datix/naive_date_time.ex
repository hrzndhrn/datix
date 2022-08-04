defmodule Datix.NaiveDateTime do
  @moduledoc """
  A `NaiveDateTime` parser using `Calendar.strftime/3` format-string.
  """

  @doc """
  Parses a datetime string into a `NaiveDateTime` according to the given `format`.

  See the `Calendar.strftime/3` documentation for how to specify a format string.

  **Time zone information is ignored**.

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

    * `:pivot_year` - a 2-digit year that represents the *pivot year* to use when
      `%y` is used. `%y` represents a 2-digit year, but Datix doesn't assume anything
      about which *century* such year refers to. For this reason, the `:pivot_year`
      option is required whenever `%y` is present in the format string; if not
      present, this function returns `{:error, :missing_pivot_year_option}`.
      For example, if `pivot_year: 65`, then the 2-digit year `64` and lower will
      refer to the current century (`2064` and so on at the time of writing this),
      while the 2-digit year `65` and higher will refer to the previous century
      (`1965` and so on).

  ## Examples

      iex> Datix.NaiveDateTime.parse("2021/01/10 12:14:24", "%Y/%m/%d %H:%M:%S")
      {:ok, ~N[2021-01-10 12:14:24]}

      iex> format = Datix.compile!("%Y/%m/%d %H:%M:%S")
      iex> Datix.NaiveDateTime.parse("2021/01/10 12:14:24", format)
      {:ok, ~N[2021-01-10 12:14:24]}

      iex> Datix.NaiveDateTime.parse("2018/06/27 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z")
      {:ok, ~N[2018-06-27 11:23:55Z]}

      iex> Datix.NaiveDateTime.parse("21/11/22", "%y/%m/%d", pivot_year: 50)
      {:ok, ~N[2021-11-22 00:00:00]}

      iex> Datix.NaiveDateTime.parse("21/11/22", "%y/%m/%d", pivot_year: 20)
      {:ok, ~N[1921-11-22 00:00:00]}

  """
  @spec parse(String.t(), String.t() | Datix.compiled(), list()) ::
          {:ok, NaiveDateTime.t()}
          | {:error,
             Datix.ValidationError.t()
             | Datix.FormatStringError.t()
             | Datix.ParseError.t()
             | Datix.OptionError.t()}
  def parse(naive_datetime_str, format, opts \\ []) do
    with {:ok, data} <- Datix.strptime(naive_datetime_str, format, opts) do
      new(data, opts)
    end
  end

  @doc """
  Parses a datetime string according to the given `format`, erroring out for
  invalid arguments.

  ## Options

  Accepts the same options as listed for `parse/3`.
  """
  @spec parse!(String.t(), String.t() | Datix.compiled(), list()) :: NaiveDateTime.t()
  def parse!(naive_datetime_str, format, opts \\ []) do
    case parse(naive_datetime_str, format, opts) do
      {:ok, naive_dt} -> naive_dt
      {:error, error} when is_exception(error) -> raise error
    end
  end

  @doc false
  def new(data, opts) do
    with {:ok, date} <- Datix.Date.new(data, opts),
         {:ok, time} <- Datix.Time.new(data, opts) do
      NaiveDateTime.new(date, time)
    end
  end
end
