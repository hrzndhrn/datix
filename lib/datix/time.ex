defmodule Datix.Time do
  @moduledoc """
  A `Time` parser using `Calendar.strftime` format-string.
  """

  @doc """
  Parses a time string according to the given `format`.

  See the `Calendar.strftime` documentation for how to specify a format-string.

  ## Options
    * `:calendar` - the calendar to build the `Time`, defaults to `Calendar.ISO`

    * `:preferred_time` - a string for the preferred format to show times,
      it can't contain the `%X` format and defaults to `"%H:%M:%S"`
      if the option is not received

    * `:am_pm_names` - a keyword list with the names of the period of the day,
      defaults to `[am: "am", pm: "pm"]`.

  Missing values will be set to minimum.

  ## Examples

      iex> Datix.Time.parse("11:12:55", "%X")
      {:ok, ~T[11:12:55]}

      iex> format = Datix.compile!("%X")
      iex> Datix.Time.parse("11:12:55", format)
      {:ok, ~T[11:12:55]}

      iex> Datix.Time.parse("10 PM", "%I %p")
      {:ok, ~T[22:00:00]}
  """
  @spec parse(String.t(), String.t() | Datix.compiled(), list()) ::
          {:ok, Time.t()}
          | {:error, :invalid_time}
          | {:error, :invalid_input}
          | {:error, {:parse_error, expected: String.t(), got: String.t()}}
          | {:error, {:conflict, [expected: term(), got: term(), modifier: String.t()]}}
          | {:error, {:invalid_string, [modifier: String.t()]}}
          | {:error, {:invalid_integer, [modifier: String.t()]}}
          | {:error, {:invalid_modifier, [modifier: String.t()]}}
  def parse(time_str, format, opts \\ []) do
    with {:ok, data} <- Datix.strptime(time_str, format, sweep(opts)) do
      new(data, opts)
    end
  end

  @doc """
  Parses a date string according to the given `format`, erroring out for
  invalid arguments.
  """
  @spec parse!(String.t(), String.t() | Datix.compiled(), list()) :: Time.t()
  def parse!(time_str, format, opts \\ []) do
    time_str
    |> Datix.strptime!(format, sweep(opts))
    |> new(opts)
    |> case do
      {:ok, time} ->
        time

      {:error, reason} ->
        raise ArgumentError, "cannot build time, reason: #{inspect(reason)}"
    end
  end

  @doc false
  def new(%{hour: hour, hour_12: hour_12} = data, opts) do
    with {:ok, hour_24} <- to_hour_24(hour_12, Map.get(data, :am_pm)) do
      case hour == hour_24 do
        true -> data |> Map.delete(:hour_12) |> new(opts)
        false -> {:error, :invalid_time}
      end
    end
  end

  def new(%{hour: h, minute: m, second: s, microsecond: ms}, opts) do
    Time.new(h, m, s, microsecond(ms), Datix.calendar(opts))
  end

  def new(%{hour_12: h_12, minute: m, second: s, microsecond: ms} = data, opts) do
    with {:ok, h} <- to_hour_24(h_12, Map.get(data, :am_pm)) do
      Time.new(h, m, s, microsecond(ms), Datix.calendar(opts))
    end
  end

  def new(data, opts), do: data |> Datix.assume(Time) |> new(opts)

  defp to_hour_24(_hour_12, nil), do: {:error, :invalid_time}
  defp to_hour_24(12, :am), do: {:ok, 0}
  defp to_hour_24(12, :pm), do: {:ok, 12}
  defp to_hour_24(hour_12, :am), do: {:ok, hour_12}
  defp to_hour_24(hour_12, :pm), do: {:ok, hour_12 + 12}

  defp microsecond(ms) when is_tuple(ms), do: ms

  defp microsecond(ms) do
    digits = Integer.digits(ms)
    precision = length(digits)
    new_ms = Integer.undigits(digits ++ List.duplicate(0, max(0, 6 - precision)))
    {new_ms, precision}
  end

  defp sweep(opts), do: Keyword.delete(opts, :calendar)
end
