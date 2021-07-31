defmodule Datix.NaiveDateTimeTest do
  use ExUnit.Case

  import Prove

  doctest Datix.NaiveDateTime

  describe "parse/3" do
    batch "parses valid date-string with format-string" do
      prove Datix.NaiveDateTime.parse("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
              {:ok, ~N[2018-12-30 11:23:55]}

      prove Datix.NaiveDateTime.parse("-2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
              {:ok, ~N[-2018-12-30 11:23:55]}
    end

    batch "parse date and time in 12 hour format" do
      prove Datix.NaiveDateTime.parse("Jan 15, 2021 12:00:00 AM", "%b %d, %Y %I:%M:%S %p") ==
              {:ok, ~N[2021-01-15 00:00:00]}

      prove Datix.NaiveDateTime.parse("Jan 15, 2021 12:00:01 AM", "%b %d, %Y %I:%M:%S %p") ==
              {:ok, ~N[2021-01-15 00:00:01]}

      prove Datix.NaiveDateTime.parse("Jan 15, 2021 11:59:59 AM", "%b %d, %Y %I:%M:%S %p") ==
              {:ok, ~N[2021-01-15 11:59:59]}

      prove Datix.NaiveDateTime.parse("Jan 15, 2021 12:00:00 PM", "%b %d, %Y %I:%M:%S %p") ==
              {:ok, ~N[2021-01-15 12:00:00]}

      prove Datix.NaiveDateTime.parse("Jan 15, 2021 01:00:00 PM", "%b %d, %Y %I:%M:%S %p") ==
              {:ok, ~N[2021-01-15 13:00:00]}

      prove Datix.NaiveDateTime.parse("Jan 15, 2021 11:59:59 PM", "%b %d, %Y %I:%M:%S %p") ==
              {:ok, ~N[2021-01-15 23:59:59]}
    end

    batch "adds missing data" do
      prove Datix.NaiveDateTime.parse("", "") == {:ok, ~N[0000-01-01 00:00:00Z]}
    end
  end

  describe "parse!/3" do
    prove "parses valid date-string",
          Datix.NaiveDateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
            ~N[2018-12-30 11:23:55]

    prove "sets calendar to default",
          Datix.NaiveDateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S").calendar ==
            Calendar.ISO

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
