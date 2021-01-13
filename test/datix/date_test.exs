defmodule Datix.DateTest do
  use ExUnit.Case

  alias Cldr.Calendar.Coptic

  doctest Datix.Date

  describe "parse/3" do
    test "parses valid date-string with format-string '%Y/%m/%d'" do
      assert Datix.Date.parse("2018/12/30", "%Y/%m/%d") == {:ok, ~D[2018-12-30]}
      assert Datix.Date.parse("-2018/12/30", "%Y/%m/%d") == {:ok, ~D[-2018-12-30]}
    end

    test "parses valid coptic date-string with format-string '%Y/%m/%d'" do
      assert Datix.Date.parse("1736/13/03", "%Y/%m/%d", calendar: Coptic) ==
               {:ok, ~D[1736-13-03 Cldr.Calendar.Coptic]}
    end

    test "parses valid date-string with format-string '%y/%m/%d'" do
      assert Datix.Date.parse("18/12/30", "%y/%m/%d") == {:ok, ~D[0018-12-30]}
    end

    test "returns error-tuple for invalid date-string with format-string '%Y/%m/%d'" do
      assert Datix.Date.parse("2018/x2/30", "%Y/%m/%d") ==
               {:error, {:invalid_integer, [modifier: "%m"]}}
    end

    test "returns error-tuple for invalid date with format-string '%Y/%m/%d'" do
      assert Datix.Date.parse("2018/99/30", "%Y/%m/%d") == {:error, :invalid_date}
    end

    test "adds day" do
      assert Datix.Date.parse("2018/12", "%Y/%m") == {:ok, ~D[2018-12-01]}
      assert Datix.Date.parse("18/12", "%y/%m") == {:ok, ~D[0018-12-01]}
    end

    test "adds day and month" do
      assert Datix.Date.parse("2018", "%Y") == {:ok, ~D[2018-01-01]}
      assert Datix.Date.parse("18", "%y") == {:ok, ~D[0018-01-01]}
      assert Datix.Date.parse("-18", "%y") == {:ok, ~D[-0018-01-01]}
    end

    test "adds year and month" do
      assert Datix.Date.parse("18", "%d") == {:ok, ~D[0000-01-18]}
    end

    test "adds year, month and day" do
      assert Datix.Date.parse("", "") == {:ok, ~D[0000-01-01]}
    end

    test "ignores time" do
      assert Datix.Date.parse("2018/12/30 12:33:55", "%Y/%m/%d %X") == {:ok, ~D[2018-12-30]}
    end

    test "validates day of week" do
      assert Datix.Date.parse("Saturday, 2019-06-01", "%A, %x") == {:ok, ~D[2019-06-01]}
      assert Datix.Date.parse("Friday, 2019-06-01", "%A, %x") == {:error, :invalid_date}
    end

    test "validates day of year" do
      assert Datix.Date.parse("152, 2019-06-01", "%j, %x") == {:ok, ~D[2019-06-01]}
      assert Datix.Date.parse("500, 2019-06-01", "%j, %x") == {:error, :invalid_date}
      assert Datix.Date.parse("001, 2019-06-01", "%j, %x") == {:error, :invalid_date}
    end

    test "validates quarter of year" do
      assert Datix.Date.parse("2, 2019-06-01", "%q, %x") == {:ok, ~D[2019-06-01]}
      assert Datix.Date.parse("1, 2019-06-01", "%q, %x") == {:error, :invalid_date}
    end
  end

  describe "parse!/3" do
    test "parses valid date-string with format-string '%Y/%m/%d'" do
      assert Datix.Date.parse!("2018/12/30", "%Y/%m/%d") == ~D[2018-12-30]
    end

    test "raises an error for an invalid format-string" do
      msg = "invalid format: %o"

      assert_raise ArgumentError, msg, fn ->
        Datix.Date.parse!("18", "%o")
      end
    end

    test "raises an error for invalid date" do
      msg = "cannot build date, reason: :invalid_date"

      assert_raise ArgumentError, msg, fn ->
        Datix.Date.parse!("2018/99/30", "%Y/%m/%d") == {:error, :invalid_date}
      end
    end
  end
end
