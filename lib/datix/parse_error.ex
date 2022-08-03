defmodule Datix.ParseError do
  @moduledoc """
  An exception for when there is an error parsing a string.
  """
  @moduledoc since: "0.3.0"

  @type reason ::
          {:expected_exact, expected :: String.t(), got :: String.t()}
          | {:conflict, expected :: term(), got :: term()}
          | :invalid_input
          | :invalid_integer
          | :invalid_string

  @type t :: %__MODULE__{reason: reason, modifier: String.t()}

  defexception [:reason, :modifier]

  @impl true
  def message(%__MODULE__{reason: reason, modifier: modifier}) do
    case reason do
      {:expected_exact, expected, got} ->
        "expected exact string #{inspect(expected)}, got: #{inspect(got)}"

      {:conflict, expected, got} when not is_nil(modifier) ->
        "expected #{inspect(expected)}, got #{inspect(got)} for #{modifier}"

      :invalid_input ->
        "invalid input"

      :invalid_integer when not is_nil(modifier) ->
        "invalid integer for #{modifier}"

      :invalid_string when not is_nil(modifier) ->
        "invalid string for #{modifier}"
    end
  end
end
