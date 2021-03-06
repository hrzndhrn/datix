defmodule Datix.DateTime do
  @moduledoc """
  A `DateTime` parser using `Calendar.strftime` format-string.
  """

  @doc """
  Parses a datetime string according to the given `format`.

  See the `Calendar.strftime` documentation for how to specify a format-string.

  The `:ok` tuple contains always an UTC datetime and a tuple with the time zone
  infos.

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

  ## Examples
  ```elixir
      iex> Datix.DateTime.parse("2021/01/10 12:14:24", "%Y/%m/%d %H:%M:%S")
      {:ok, ~U[2021-01-10 12:14:24Z], {"UTC", 0}}

      iex> Datix.DateTime.parse("2018/06/27 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z")
      {:ok, ~U[2018-06-27 09:23:55Z], {"CEST", 7_200}}
  ```
  """
  @spec parse(String.t(), String.t(), list()) ::
          {:ok, DateTime.t(), {String.t(), integer()}}
          | {:error, :invalid_date}
          | {:error, :invalid_input}
          | {:error, {:parse_error, expected: String.t(), got: String.t()}}
          | {:error, {:conflict, [expected: term(), got: term(), modifier: String.t()]}}
          | {:error, {:invalid_string, [modifier: String.t()]}}
          | {:error, {:invalid_integer, [modifier: String.t()]}}
          | {:error, {:invalid_modifier, [modifier: String.t()]}}
  def parse(datetime_str, format_str, opts \\ []) do
    with {:ok, data} <- Datix.strptime(datetime_str, format_str, opts) do
      new(data, opts)
    end
  end

  @doc """
  Parses a datetime string according to the given `format`, erroring out for
  invalid arguments.

  This function is just defined for UTC datetimes.

  ## Examples
  ```elixir
      iex> Datix.DateTime.parse!("2018/06/27 11:23:55 UTC+0000", "%Y/%m/%d %H:%M:%S %Z%z")
      ~U[2018-06-27 11:23:55Z]

      iex> Datix.DateTime.parse!("2018/06/27 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z")
      ** (ArgumentError) parse!/3 is just defined for UTC, not for CEST
  ```
  """
  @spec parse!(String.t(), String.t(), list()) :: DateTime.t()
  def parse!(datetime_str, format_str, opts \\ []) do
    datetime_str
    |> Datix.strptime!(format_str, opts)
    |> new(opts)
    |> case do
      {:ok, datetime, {"UTC", 0}} ->
        datetime

      {:ok, _datetime, {zone_abbr, _zone_offset}} ->
        raise ArgumentError, "parse!/3 is just defined for UTC, not for #{zone_abbr}"

      {:error, reason} ->
        raise ArgumentError, "cannot build date-time, reason: #{inspect(reason)}"
    end
  end

  @doc false
  def new(data, opts) do
    with {:ok, date} <- Datix.Date.new(data, opts),
         {:ok, time} <- Datix.Time.new(data, opts),
         {:ok, datetime} <- DateTime.new(date, time) do
      time_zone(datetime, data)
    end
  end

  defp time_zone(datetime, data) do
    case {Map.get(data, :zone_abbr), Map.get(data, :zone_offset)} do
      {nil, nil} ->
        {:ok, datetime, {"UTC", 0}}

      {nil, 0} ->
        {:ok, datetime, {"UTC", 0}}

      {nil, zone_offset} = zone ->
        {:ok, DateTime.add(datetime, -1 * zone_offset), zone}

      {"UTC", 0} ->
        {:ok, datetime, {"UTC", 0}}

      {_zone_abbr, zone_offset} = zone ->
        {:ok, DateTime.add(datetime, -1 * zone_offset), zone}
    end
  end
end
