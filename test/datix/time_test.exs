defmodule Datix.TimeTest do
  use ExUnit.Case

  doctest Datix.Time

  describe "parse/3" do
    test "parses valid time-string with format-string '%H:%M:%S.%f'" do
      assert Datix.Time.parse("11:24:33.555", "%H:%M:%S.%f") == {:ok, ~T[11:24:33.555]}
    end

    test "parses valid time-string with format-string '%H:%M:%S'" do
      assert Datix.Time.parse("11:24:33", "%H:%M:%S") == {:ok, ~T[11:24:33]}
    end

    test "parses valid time-string with format-string '%H:%M'" do
      assert Datix.Time.parse("11:24", "%H:%M") == {:ok, ~T[11:24:00]}
    end

    test "parses valid time-string with format-string '%H'" do
      assert Datix.Time.parse("01", "%H") == {:ok, ~T[01:00:00]}
    end

    test "parses valid time-string with format-string '%I %p'" do
      assert Datix.Time.parse("01 AM", "%I %p") == {:ok, ~T[01:00:00]}
    end

    test "parses valid time-string with format-string '%-I %p'" do
      assert Datix.Time.parse("2 AM", "%-I %p") == {:ok, ~T[02:00:00]}
      assert Datix.Time.parse("4 PM", "%-I %p") == {:ok, ~T[16:00:00]}
    end

    test "parses valid time-string with format-string '%I %P'" do
      assert Datix.Time.parse("03 pm", "%I %P") == {:ok, ~T[15:00:00]}
      assert Datix.Time.parse("01 am", "%I %P") == {:ok, ~T[01:00:00]}
    end

    test "parses valid time-string with format-string '%I %P - %H'" do
      assert Datix.Time.parse("01 pm - 13", "%I %P - %H") == {:ok, ~T[13:00:00]}
    end

    test "returns error-tuple for invalid hour combinations" do
      assert Datix.Time.parse("01 pm - 10", "%I %P - %H") == {:error, :invalid_time}
      assert Datix.Time.parse("01 - 10", "%I - %H") == {:error, :invalid_time}
    end

    test "returns error-tuple for invalid time" do
      assert Datix.Time.parse("11:24:33.123456789", "%H:%M:%S.%f") == {:error, :invalid_time}
      assert Datix.Time.parse("99:24:33.123", "%H:%M:%S.%f") == {:error, :invalid_time}
    end

    test "ignores valid date" do
      assert Datix.Time.parse("2020-01-01 11:24:33", "%Y-%m-%d %H:%M:%S") == {:ok, ~T[11:24:33]}
    end

    test "ignores invalid date" do
      assert Datix.Time.parse("2020-99-01 11:24:33", "%Y-%m-%d %H:%M:%S") == {:ok, ~T[11:24:33]}
    end

    test "returns error-tuple for invalid date format" do
      assert Datix.Time.parse("2020-XX-01 11:24:33", "%Y-%m-%d %H:%M:%S") ==
               {:error, {:invalid_integer, [modifier: "%m"]}}
    end

    test "adds hour" do
      assert Datix.Time.parse("24:33", "%M:%S") == {:ok, ~T[00:24:33]}
    end

    test "adds hour and minute" do
      assert Datix.Time.parse("33", "%S") == {:ok, ~T[00:00:33]}
    end

    test "adds hour, minute and second" do
      assert Datix.Time.parse("", "") == {:ok, ~T[00:00:00]}
    end
  end

  describe "parse!/3" do
    test "parses valid time-string with format-string '%H:%M:%S.%f'" do
      assert Datix.Time.parse!("11:24:33.555", "%H:%M:%S.%f") == ~T[11:24:33.555]
    end

    test "raises an error for invalid time" do
      msg = "cannot build time, reason: :invalid_time"

      assert_raise ArgumentError, msg, fn ->
        Datix.Time.parse!("99:24:33.555", "%H:%M:%S.%f")
      end
    end
  end
end
