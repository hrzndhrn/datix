defmodule Datix.TimeTest do
  use ExUnit.Case

  import Prove

  alias Datix.ValidationError

  doctest Datix.Time

  describe "parse/3" do
    batch "parses valid time-string:" do
      prove Datix.Time.parse("11:24:33.555", "%H:%M:%S.%f") == {:ok, ~T[11:24:33.555]}
      prove Datix.Time.parse("11:24:33", "%H:%M:%S") == {:ok, ~T[11:24:33]}
      prove Datix.Time.parse("11:24", "%H:%M") == {:ok, ~T[11:24:00]}
      prove Datix.Time.parse("01", "%H") == {:ok, ~T[01:00:00]}
      prove Datix.Time.parse("01 AM", "%I %p") == {:ok, ~T[01:00:00]}
      prove Datix.Time.parse("2 AM", "%-I %p") == {:ok, ~T[02:00:00]}
      prove Datix.Time.parse("4 PM", "%-I %p") == {:ok, ~T[16:00:00]}
      prove Datix.Time.parse("03 pm", "%I %P") == {:ok, ~T[15:00:00]}
      prove Datix.Time.parse("01 am", "%I %P") == {:ok, ~T[01:00:00]}
      prove Datix.Time.parse("01 pm - 13", "%I %P - %H") == {:ok, ~T[13:00:00]}
    end

    batch "returns error-tuple:" do
      prove Datix.Time.parse("01 pm - 10", "%I %P - %H") ==
              {:error, %ValidationError{reason: :invalid_time, module: Datix.Time}}

      prove Datix.Time.parse("01 - 10", "%I - %H") ==
              {:error, %ValidationError{reason: :invalid_time, module: Datix.Time}}

      prove Datix.Time.parse("11:24:33.123456789", "%H:%M:%S.%f") ==
              {:error, %ValidationError{reason: :invalid_time, module: Datix.Time}}

      prove Datix.Time.parse("99:24:33.123", "%H:%M:%S.%f") ==
              {:error, %ValidationError{reason: :invalid_time, module: Datix.Time}}

      prove Datix.Time.parse("99:24:33 PM", "%I:%M:%S %p") ==
              {:error, %ValidationError{reason: :invalid_time, module: Datix.Time}}
    end

    batch "ignores valid/invalid date:" do
      prove Datix.Time.parse("2020-01-01 11:24:33", "%Y-%m-%d %H:%M:%S") == {:ok, ~T[11:24:33]}
      prove Datix.Time.parse("2020-99-01 11:24:33", "%Y-%m-%d %H:%M:%S") == {:ok, ~T[11:24:33]}
    end

    batch "returns error-tuple for invalid date format:" do
      prove Datix.Time.parse("2020-XX-01 11:24:33", "%Y-%m-%d %H:%M:%S") ==
              {:error, %Datix.ParseError{reason: :invalid_integer, modifier: "%m"}}

      prove Datix.Time.parse("foo 11:24:33", "%Y-%m-%d %H:%M:%S") ==
              {:error, %Datix.ParseError{reason: :invalid_integer, modifier: "%Y"}}
    end

    batch "adds hour, minute and/or second:" do
      prove Datix.Time.parse("24:33", "%M:%S") == {:ok, ~T[00:24:33]}
      prove Datix.Time.parse("33", "%S") == {:ok, ~T[00:00:33]}
      prove Datix.Time.parse("", "") == {:ok, ~T[00:00:00]}
    end
  end

  describe "parse!/3" do
    prove "parses valid time-string",
          Datix.Time.parse!("11:24:33.555", "%H:%M:%S.%f") == ~T[11:24:33.555]

    test "raises an error for invalid time" do
      assert_raise ValidationError, "time is not valid", fn ->
        Datix.Time.parse!("99:24:33.555", "%H:%M:%S.%f")
      end
    end
  end
end
