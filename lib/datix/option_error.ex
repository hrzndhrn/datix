defmodule Datix.OptionError do
  @moduledoc """
  An exception that represents an error with some options.
  """
  @moduledoc since: "0.3.0"

  @type reason :: :missing | :unknown

  @type t :: %__MODULE__{reason: reason, option: atom}

  defexception [:reason, :option]

  @impl true
  def message(%__MODULE__{reason: reason, option: option}) do
    case reason do
      :missing -> "missing option #{inspect(option)}"
      :unknown -> "unknown option #{inspect(option)}"
    end
  end
end
