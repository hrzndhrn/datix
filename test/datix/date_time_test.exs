defmodule Datix.DateTimeTest do
  use ExUnit.Case

  import Prove

  alias Datix.ValidationError

  doctest Datix.DateTime

  describe "parse/3" do
    batch "parses valid date-string" do
      prove Datix.DateTime.parse("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
              {:ok, ~U[2018-12-30 11:23:55Z], {"UTC", 0}}

      prove Datix.DateTime.parse("-2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
              {:ok, ~U[-2018-12-30 11:23:55Z], {"UTC", 0}}

      prove Datix.DateTime.parse("2018/12/30 11:23:55 CEST+0200", "%Y/%m/%d %H:%M:%S %Z%z") ==
              {:ok, ~U[2018-12-30 09:23:55Z], {"CEST", 7_200}}

      prove Datix.DateTime.parse("2018/12/30 11:23:55 UTC+0000", "%Y/%m/%d %H:%M:%S %Z%z") ==
              {:ok, ~U[2018-12-30 11:23:55Z], {"UTC", 0}}

      prove Datix.DateTime.parse("2018/12/30 11:23:55 -0300", "%Y/%m/%d %H:%M:%S %z") ==
              {:ok, ~U[2018-12-30 14:23:55Z], {nil, -10_800}}

      prove Datix.DateTime.parse("2018/12/30 11:23:55 -0000", "%Y/%m/%d %H:%M:%S %z") ==
              {:ok, ~U[2018-12-30 11:23:55Z], {"UTC", 0}}

      prove Datix.DateTime.parse("2022-08-02 09:10:00 CEST", "%Y-%m-%d %H:%M:%S %Z") ==
              {:ok, ~U[2022-08-02 09:10:00Z], {"CEST", nil}}

      # With 2-year digits, it figures out the right century.

      prove Datix.DateTime.parse("20-Jan-21 01:02:03", "%d-%b-%y %H:%M:%S", pivot_year: 50) ==
              {:ok, ~U[2021-01-20 01:02:03Z], {"UTC", 0}}

      prove Datix.DateTime.parse("20-Jan-88 01:02:03", "%d-%b-%y %H:%M:%S", pivot_year: 50) ==
              {:ok, ~U[1988-01-20 01:02:03Z], {"UTC", 0}}

      prove Datix.DateTime.parse("20-Jan-88 01:02:03", "%d-%b-%y %H:%M:%S", pivot_year: 87) ==
              {:ok, ~U[1988-01-20 01:02:03Z], {"UTC", 0}}
    end

    batch "adds missing data" do
      prove Datix.DateTime.parse("", "") == {:ok, ~U[0000-01-01 00:00:00Z], {"UTC", 0}}
      prove Datix.DateTime.parse("2020", "%Y") == {:ok, ~U[2020-01-01 00:00:00Z], {"UTC", 0}}
    end
  end

  describe "parse!/3" do
    prove "parses valid date-string",
          Datix.DateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S") ==
            ~U[2018-12-30 11:23:55Z]

    prove "sets calendar to default",
          Datix.DateTime.parse!("2018/12/30 11:23:55", "%Y/%m/%d %H:%M:%S").calendar ==
            Calendar.ISO

    test "raises an error for an invalid time" do
      assert_raise ValidationError, "time is not valid", fn ->
        Datix.DateTime.parse!("2018/12/30 99:23:55", "%Y/%m/%d %H:%M:%S")
      end
    end

    test "raises an error for an invalid date" do
      assert_raise ValidationError, "date is not valid", fn ->
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
