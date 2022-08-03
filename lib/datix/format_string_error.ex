defmodule Datix.FormatStringError do
  @moduledoc """
  An exception for when the format string is invalid.
  """

  @moduledoc since: "v0.3.0"

  @type reason :: {:invalid_modifier, String.t()}

  @type t :: %__MODULE__{reason: reason}

  defexception [:reason]

  @impl true
  def message(%__MODULE__{reason: reason}) do
    {:invalid_modifier, modifier} = reason
    "invalid format string because of invalid modifier: #{modifier}"
  end
end
