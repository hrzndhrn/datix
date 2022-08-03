defmodule Datix.ValidationError do
  @moduledoc """
  An exception for when a date or time fails validation.

  An "invalid" date or time is a date or time that gets parsed correctly,
  but that is semantically invalid. For example, a date with a day of `99`
  is invalid.
  """
  @moduledoc since: "0.3.0"

  @type reason :: :invalid_date | :invalid_time

  @type t :: %__MODULE__{reason: reason, module: module}

  defexception [:reason, :module]

  @impl true
  def message(%__MODULE__{reason: reason, module: _module}) do
    case reason do
      :invalid_date -> "date is not valid"
      :invalid_time -> "time is not valid"
    end
  end
end
