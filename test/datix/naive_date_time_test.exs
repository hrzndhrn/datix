defmodule Datix.NaiveDateTimeTest do
  use ExUnit.Case

  doctest Datix.NaiveDateTime

  describe "parse/3" do
    test "parses valid date-string with format-string '%Y/%m/%d %H:%M:%S'" do
      assert Datix.NaiveDateTime.parse("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
               {:ok, ~N[2018-12-30 11:23:55]}

      assert Datix.NaiveDateTime.parse("-2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
               {:ok, ~N[-2018-12-30 11:23:55]}
    end

    test "adds missing data" do
      assert Datix.NaiveDateTime.parse("", "") == {:ok, ~N[0000-01-01 00:00:00Z]}
    end
  end

  describe "parse!/3" do
    test "parses valid date-string with format-string '%Y/%m/%d %H:%M:%S'" do
      assert Datix.NaiveDateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
               ~N[2018-12-30 11:23:55]
    end

    test "sets calendar to default" do
      naive_datetime = Datix.NaiveDateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S")
      assert naive_datetime.calendar == Calendar.ISO
    end

    test "raises an error for an invalid time" do
      msg = "cannot build naive-date-time, reason: :invalid_time"

      assert_raise ArgumentError, msg, fn ->
        Datix.NaiveDateTime.parse!("2018/12/30 99:23:55", "%Y/%m/%d %H:%M:%S")
      end
    end

    test "raises an error for an invalid date" do
      msg = "cannot build naive-date-time, reason: :invalid_date"

      assert_raise ArgumentError, msg, fn ->
        Datix.NaiveDateTime.parse!("2018/99/30 99:23:55", "%Y/%m/%d %H:%M:%S")
      end
    end
  end
end
