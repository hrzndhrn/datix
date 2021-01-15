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

    test "parse date and time in 12 hour format (12:00:00 AM)" do
      assert Datix.NaiveDateTime.parse("Jan 15, 2021 12:00:00 AM", "%b %d, %Y %I:%M:%S %p") ==
               {:ok, ~N[2021-01-15 00:00:00]}
    end

    test "parse date and time in 12 hour format (12:00:01 AM)" do
      assert Datix.NaiveDateTime.parse("Jan 15, 2021 12:00:01 AM", "%b %d, %Y %I:%M:%S %p") ==
               {:ok, ~N[2021-01-15 00:00:01]}
    end

    test "parse date and time in 12 hour format (11:59:59 AM)" do
      assert Datix.NaiveDateTime.parse("Jan 15, 2021 11:59:59 AM", "%b %d, %Y %I:%M:%S %p") ==
               {:ok, ~N[2021-01-15 11:59:59]}
    end

    test "parse date and time in 12 hour format (12:00:00 PM)" do
      assert Datix.NaiveDateTime.parse("Jan 15, 2021 12:00:00 PM", "%b %d, %Y %I:%M:%S %p") ==
               {:ok, ~N[2021-01-15 12:00:00]}
    end

    test "parse date and time in 12 hour format (01:00:00 PM)" do
      assert Datix.NaiveDateTime.parse("Jan 15, 2021 01:00:00 PM", "%b %d, %Y %I:%M:%S %p") ==
               {:ok, ~N[2021-01-15 13:00:00]}
    end

    test "parse date and time in 12 hour format (11:59:59 PM)" do
      assert Datix.NaiveDateTime.parse("Jan 15, 2021 11:59:59 PM", "%b %d, %Y %I:%M:%S %p") ==
               {:ok, ~N[2021-01-15 23:59:59]}
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
