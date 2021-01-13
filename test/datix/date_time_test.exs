defmodule Datix.DateTimeTest do
  use ExUnit.Case

  doctest Datix.DateTime

  describe "parse/3" do
    test "parses valid date-string with format-string '%Y/%m/%d %H:%M:%S'" do
      assert Datix.DateTime.parse("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
               {:ok, ~U[2018-12-30 11:23:55Z], {"UTC", 0}}
      assert Datix.DateTime.parse("-2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
               {:ok, ~U[-2018-12-30 11:23:55Z], {"UTC", 0}}
    end

    test "parses valid date-string with format-string '%Y/%m/%d %H:%M:%S %Z%z'" do
      assert Datix.DateTime.parse("2018/12/30 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z") ==
               {:ok, ~U[2018-12-30 09:23:55Z], {"CEST", 7_200}}

      assert Datix.DateTime.parse("2018/12/30 11:23:55 UTC+0000", "%Y/%m/%d %H:%M:%S %Z%z") ==
               {:ok, ~U[2018-12-30 11:23:55Z], {"UTC", 0}}
    end

    test "parses valid date-string with format-string '%Y/%m/%d %H:%M:%S %z'" do
      assert Datix.DateTime.parse("2018/12/30 11:23:55 -0300", "%Y/%m/%d %H:%M:%S %z") ==
               {:ok, ~U[2018-12-30 14:23:55Z], {nil, -10_800}}

      assert Datix.DateTime.parse("2018/12/30 11:23:55 -0000", "%Y/%m/%d %H:%M:%S %z") ==
               {:ok, ~U[2018-12-30 11:23:55Z], {"UTC", 0}}
    end

    test "adds missing data" do
      assert Datix.DateTime.parse("", "") == {:ok, ~U[0000-01-01 00:00:00Z], {"UTC", 0}}
    end
  end

  describe "parse!/3" do
    test "parses valid date-string with format-string '%Y/%m/%d %H:%M:%S'" do
      assert Datix.DateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
               ~U[2018-12-30 11:23:55Z]
    end

    test "sets calendar to default" do
      datetime = Datix.DateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S")
      assert datetime.calendar == Calendar.ISO
    end

    test "raises an error for an invalid time" do
      msg = "cannot build date-time, reason: :invalid_time"

      assert_raise ArgumentError, msg, fn ->
        Datix.DateTime.parse!("2018/12/30 99:23:55", "%Y/%m/%d %H:%M:%S")
      end
    end

    test "raises an error for an invalid date" do
      msg = "cannot build date-time, reason: :invalid_date"

      assert_raise ArgumentError, msg, fn ->
        Datix.DateTime.parse!("2018/99/30 99:23:55", "%Y/%m/%d %H:%M:%S")
      end
    end

    test "raises an error for none UTC time-zone" do
      msg = "parse!/3 is just defined for UTC, not for FOO"

      assert_raise ArgumentError, msg, fn ->
        Datix.DateTime.parse!("2018/11/30 23:23:55 FOO +9000", "%Y/%m/%d %H:%M:%S %Z %z")
      end
    end
  end
end
