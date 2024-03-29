defmodule Datix.DateTest do
  use ExUnit.Case

  import Prove

  alias Cldr.Calendar.Coptic
  alias Datix.OptionError
  alias Datix.ValidationError

  doctest Datix.Date

  describe "parse/3" do
    batch "parses valid date-string:" do
      prove Datix.Date.parse("2018/12/30", "%Y/%m/%d") == {:ok, ~D[2018-12-30]}
      prove Datix.Date.parse("-2018/12/30", "%Y/%m/%d") == {:ok, ~D[-2018-12-30]}
      prove Datix.Date.parse("18/12/30", "%y/%m/%d", pivot_year: 50) == {:ok, ~D[2018-12-30]}

      prove Datix.Date.parse("1736/13/03", "%Y/%m/%d", calendar: Coptic) ==
              {:ok, ~D[1736-13-03 Cldr.Calendar.Coptic]}

      prove Datix.Date.parse("49-01-01", "%y-%m-%d", pivot_year: 50) == {:ok, ~D[2049-01-01]}
      prove Datix.Date.parse("51-01-01", "%y-%m-%d", pivot_year: 50) == {:ok, ~D[1951-01-01]}
    end

    batch "returns error-tuple for invalid date-string:" do
      prove Datix.Date.parse("2018/x2/30", "%Y/%m/%d") ==
              {:error, %Datix.ParseError{reason: :invalid_integer, modifier: "%m"}}

      prove Datix.Date.parse("2018/99/30", "%Y/%m/%d") ==
              {:error,
               %ValidationError{
                 reason: :invalid_date,
                 module: Datix.Date
               }}
    end

    batch "returns error-tuple for missing :pivot_year option when using %y:" do
      prove Datix.Date.parse("99", "%y") ==
              {:error, %OptionError{reason: :missing, option: :pivot_year}}
    end

    batch "adds day, month, and/or year:" do
      prove Datix.Date.parse("2018/12", "%Y/%m") == {:ok, ~D[2018-12-01]}
      prove Datix.Date.parse("18/12", "%y/%m", pivot_year: 50) == {:ok, ~D[2018-12-01]}
      prove Datix.Date.parse("2018", "%Y") == {:ok, ~D[2018-01-01]}
      prove Datix.Date.parse("18", "%y", pivot_year: 50) == {:ok, ~D[2018-01-01]}
      prove Datix.Date.parse("-18", "%y", pivot_year: 50) == {:ok, ~D[-0018-01-01]}
      prove Datix.Date.parse("18", "%d") == {:ok, ~D[0000-01-18]}
      prove Datix.Date.parse("", "") == {:ok, ~D[0000-01-01]}
    end

    batch "ignores time" do
      prove Datix.Date.parse("2018/12/30 12:33:55", "%Y/%m/%d %X") == {:ok, ~D[2018-12-30]}
    end

    batch "validates day of week" do
      prove Datix.Date.parse("Saturday, 2019-06-01", "%A, %x") == {:ok, ~D[2019-06-01]}

      prove Datix.Date.parse("Friday, 2019-06-01", "%A, %x") ==
              {:error,
               %ValidationError{
                 reason: :invalid_date,
                 module: Datix.Date
               }}
    end

    batch "validates day of year" do
      prove Datix.Date.parse("152, 2019-06-01", "%j, %x") == {:ok, ~D[2019-06-01]}

      prove Datix.Date.parse("500, 2019-06-01", "%j, %x") ==
              {:error,
               %ValidationError{
                 reason: :invalid_date,
                 module: Datix.Date
               }}

      prove Datix.Date.parse("001, 2019-06-01", "%j, %x") ==
              {:error,
               %ValidationError{
                 reason: :invalid_date,
                 module: Datix.Date
               }}
    end

    batch "validates quarter of year" do
      prove Datix.Date.parse("2, 2019-06-01", "%q, %x") == {:ok, ~D[2019-06-01]}

      prove Datix.Date.parse("1, 2019-06-01", "%q, %x") ==
              {:error,
               %ValidationError{
                 reason: :invalid_date,
                 module: Datix.Date
               }}
    end
  end

  describe "parse!/3" do
    prove "parses valid date-string",
          Datix.Date.parse!("2018/12/30", "%Y/%m/%d") == ~D[2018-12-30]

    test "raises an error for an invalid format-string" do
      assert_raise Datix.FormatStringError, ~r/invalid modifier: %o/, fn ->
        Datix.Date.parse!("18", "%o")
      end
    end

    test "raises an error for invalid date" do
      assert_raise ValidationError, "date is not valid", fn ->
        Datix.Date.parse!("2018/99/30", "%Y/%m/%d")
      end
    end

    test "raises an error for missing :pivot_year option when using %y" do
      assert_raise OptionError, "missing option :pivot_year", fn ->
        Datix.Date.parse!("99", "%y")
      end
    end
  end
end
