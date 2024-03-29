defmodule Datix.Time do
  @moduledoc """
  A `Time` parser using `Calendar.strftime/3` format-string.
  """

  alias Datix.ValidationError

  @doc """
  Parses a time string according to the given `format`.

  See the `Calendar.strftime/3` documentation for how to specify a format string.

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
          | {:error,
             Datix.FormatStringError.t()
             | Datix.ValidationError.t()
             | Datix.ParseError.t()
             | Datix.OptionError.t()}
  def parse(time_str, format, opts \\ []) do
    with {:ok, data} <- Datix.strptime(time_str, format, sweep(opts)) do
      new(data, opts)
    end
  end

  @doc """
  Parses a date string according to the given `format`, erroring out for
  invalid arguments.

  ## Options

  Accepts the same options as listed for `parse/3`.
  """
  @spec parse!(String.t(), String.t() | Datix.compiled(), list()) :: Time.t()
  def parse!(time_str, format, opts \\ []) do
    case parse(time_str, format, opts) do
      {:ok, time} -> time
      {:error, error} when is_exception(error) -> raise error
    end
  end

  @doc false
  def new(%{hour: hour, hour_12: hour_12} = data, opts) do
    with {:ok, hour_24} <- to_hour_24(hour_12, Map.get(data, :am_pm)) do
      case hour == hour_24 do
        true -> data |> Map.delete(:hour_12) |> new(opts)
        false -> {:error, %ValidationError{reason: :invalid_time, module: __MODULE__}}
      end
    end
  end

  def new(%{hour: h, minute: m, second: s, microsecond: ms}, opts) do
    case Time.new(h, m, s, microsecond(ms), Datix.calendar(opts)) do
      {:ok, time} ->
        {:ok, time}

      {:error, :invalid_time} ->
        {:error, %ValidationError{reason: :invalid_time, module: __MODULE__}}
    end
  end

  def new(%{hour_12: h_12, minute: m, second: s, microsecond: ms} = data, opts) do
    with {:ok, h} <- to_hour_24(h_12, Map.get(data, :am_pm)) do
      case Time.new(h, m, s, microsecond(ms), Datix.calendar(opts)) do
        {:ok, time} ->
          {:ok, time}

        {:error, :invalid_time} ->
          {:error, %ValidationError{reason: :invalid_time, module: __MODULE__}}
      end
    end
  end

  def new(data, opts), do: data |> Datix.assume(Time) |> new(opts)

  defp to_hour_24(_hour_12, nil),
    do: {:error, %ValidationError{reason: :invalid_time, module: __MODULE__}}

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
