defmodule DatixTest do
  use ExUnit.Case

  doctest Datix

  describe "parse/3" do
    # Without modifiers

    test "parses empty string" do
      assert Datix.strptime("", "") == {:ok, %{}}
    end

    test "parses string without modifiers" do
      assert Datix.strptime("foo", "foo") == {:ok, %{}}
    end

    test "returns error tuple for invalid input" do
      assert Datix.strptime("foobar", "foo") == {:error, :invalid_input}
      assert Datix.strptime("foo", "foobar") == {:error, :invalid_input}
    end

    test "returns error tuple for different string without modifiers" do
      assert Datix.strptime("foobar", "foopar") ==
               {:error, {:parse_error, expected: "p", got: "b"}}
    end

    test "returns an error tuple for an unknown option" do
      assert Datix.strptime("", "", foo: :bar) == {:error, {:unknown, option: :foo}}
    end

    # Invalid modifier

    test "returns error tuple for invalid modifier" do
      assert Datix.strptime("foo", "%l") == {:error, {:invalid_modifier, [modifier: "%l"]}}
    end

    # %a - Abbreviated name of day

    test "parses with format-string '%a'" do
      assert Datix.strptime("Wed", "%a") == {:ok, %{day_of_week: 3}}
    end

    test "returns error tuple for invalid value for modifier %a" do
      assert Datix.strptime("Xan", "%a") == {:error, {:invalid_string, [modifier: "%a"]}}
    end

    test "parses with format-string '%06a'" do
      assert Datix.strptime("000Wed", "%06a") == {:ok, %{day_of_week: 3}}
    end

    test "returns error tuple for invalid value for modifier %06a" do
      assert Datix.strptime("000foo", "%06a") == {:error, {:invalid_string, [modifier: "%06a"]}}
    end

    # %A - Full name of day

    test "parses with format-string '%A'" do
      assert Datix.strptime("Friday", "%A") == {:ok, %{day_of_week: 5}}
    end

    test "returns error tuple for invalid value for modifier %A" do
      assert Datix.strptime("Xan", "%A") == {:error, {:invalid_string, [modifier: "%A"]}}
    end

    # %b - Abbreviated month name

    test "parses with format-string '%b'" do
      assert Datix.strptime("Dec", "%b") == {:ok, %{month: 12}}
    end

    test "returns error tuple for invalid value for modifier %b" do
      assert Datix.strptime("Xan", "%b") == {:error, {:invalid_string, [modifier: "%b"]}}
    end

    # %B - Full month name

    test "parses with format-string '%B'" do
      assert Datix.strptime("November", "%B") == {:ok, %{month: 11}}
    end

    test "returns error tuple for invalid value for modifier %B" do
      assert Datix.strptime("Xan", "%B") == {:error, {:invalid_string, [modifier: "%B"]}}
    end

    # %c - Preferred date+time representation

    test "parses with format-string '%c'" do
      assert Datix.strptime("2018-10-17 12:34:56", "%c") ==
               {:ok, %{day: 17, hour: 12, minute: 34, month: 10, second: 56, year: 2018}}
    end

    test "parses with format-string '%c' and preferred '%x/%X'" do
      assert Datix.strptime("2018-10-17/12:34:56", "%c", preferred_datetime: "%x/%X") ==
               {:ok, %{day: 17, hour: 12, minute: 34, month: 10, second: 56, year: 2018}}
    end

    test "returns error tuple for invalid value for modifier %c" do
      assert Datix.strptime("2020-foo", "%c") == {:error, {:invalid_integer, [modifier: "%m"]}}
    end

    # %d - Day of the month

    test "parses with format-string '%d'" do
      assert Datix.strptime("30", "%d") == {:ok, %{day: 30}}
    end

    test "returns error tuple for invalid value for modifier %d" do
      assert Datix.strptime("2foo", "%d") == {:error, {:invalid_integer, [modifier: "%d"]}}
    end

    # %f - Microseconds

    test "parses with format-string '%f'" do
      assert Datix.strptime("1234", "%f") == {:ok, %{microsecond: 1234}}
    end

    test "parses with format-string 'x%fy'" do
      assert Datix.strptime("x1234y", "x%fy") == {:ok, %{microsecond: 1234}}
    end

    test "returns error tuple for invalid value for modifier %f" do
      assert Datix.strptime("xy", "x%fy") == {:error, {:invalid_integer, [modifier: "%f"]}}
    end

    # %H - Hour using a 24-hour clock

    test "parses with format-string '%H'" do
      assert Datix.strptime("54", "%H") == {:ok, %{hour: 54}}
    end

    test "returns error tuple for invalid value for modifier %H" do
      assert Datix.strptime("4", "%H") == {:error, {:invalid_integer, [modifier: "%H"]}}
    end

    test "returns error tuple for negative value for modifier %H" do
      assert Datix.strptime("-14", "%H") == {:error, {:invalid_integer, [modifier: "%H"]}}
    end

    # %I - Hour using a 12-hour clock

    test "parses with format-string '%I'" do
      assert Datix.strptime("54", "%I") == {:ok, %{hour_12: 54}}
    end

    # %j - Day of the year

    test "parses with format-string '%j'" do
      assert Datix.strptime("154", "%j") == {:ok, %{day_of_year: 154}}
    end

    # %m - Month

    test "parses with format-string '%m'" do
      assert Datix.strptime("33", "%m") == {:ok, %{month: 33}}
    end

    # %M - Minute

    test "parses with format-string '%M'" do
      assert Datix.strptime("33", "%M") == {:ok, %{minute: 33}}
    end

    # %p - AM or PM

    test "parses with format-string '%p'" do
      assert Datix.strptime("PM", "%p") == {:ok, %{am_pm: :pm}}
    end

    # %P - am or pm

    test "parses with format-string '%P'" do
      assert Datix.strptime("am", "%P") == {:ok, %{am_pm: :am}}
    end

    # %q - quarter

    test "parses with format-string '%q'" do
      assert Datix.strptime("3", "%q") == {:ok, %{quarter: 3}}
    end

    test "returns error tuple for invalid value for modifier %q" do
      assert Datix.strptime("-", "%q") == {:error, {:invalid_integer, [modifier: "%q"]}}
    end

    test "parses with format-string '%03q'" do
      assert Datix.strptime("003", "%03q") == {:ok, %{quarter: 3}}
    end

    test "parses with format-string '%_3q'" do
      assert Datix.strptime("  3", "%_3q") == {:ok, %{quarter: 3}}
    end

    # %S - Second

    test "parses with format-string '%S'" do
      assert Datix.strptime("99", "%S") == {:ok, %{second: 99}}
    end

    test "returns error tuple for invalid value for modifier %S" do
      assert Datix.strptime("9-", "%S") == {:error, {:invalid_integer, [modifier: "%S"]}}
    end

    # %u - Day of the week

    test "parses with format-string '%u'" do
      assert Datix.strptime("4", "%u") == {:ok, %{day_of_week: 4}}
      assert Datix.strptime("9", "%u") == {:ok, %{day_of_week: 9}}
    end

    # %x - Preferred date (without time) representation

    test "parses with format-string '%x'" do
      assert Datix.strptime("2018-10-17", "%x") == {:ok, %{day: 17, month: 10, year: 2018}}
    end

    test "parses with format-string '%x' and preferred '%Y/%m/%d'" do
      assert Datix.strptime("2018/10/17", "%x", preferred_date: "%Y/%m/%d") ==
               {:ok, %{day: 17, month: 10, year: 2018}}
    end

    test "returns error tuple for cycle in format-string" do
      assert Datix.strptime("2018/10/17", "%x", preferred_date: "%Y/%x") ==
               {:error, {:cycle, "%x"}}
    end

    # %X - Preferred time (without date) representation

    test "parses with format-string '%X'" do
      assert Datix.strptime("11:12:13", "%X") == {:ok, %{hour: 11, minute: 12, second: 13}}
    end

    # %y - Year as 2-digits

    test "parses with format-string '%y'" do
      assert Datix.strptime("12", "%y") == {:ok, %{year_2_digit: 12}}
    end

    test "parses with format-string '%y' and a negative year" do
      assert Datix.strptime("-12", "%y") == {:ok, %{year_2_digit: -12}}
    end

    test "returns error tuple for invalid value for modifier %y" do
      assert Datix.strptime("1A", "%y") == {:error, {:invalid_integer, [modifier: "%y"]}}
    end

    # %Y - Year

    test "parses with format-string '%Y'" do
      assert Datix.strptime("1972", "%Y") == {:ok, %{year: 1972}}
    end

    test "parses with format-string '%Y' and a negative year" do
      assert Datix.strptime("-1972", "%Y") == {:ok, %{year: -1972}}
    end

    # %z - +hhmm/-hhmm time zone offset from UTC

    test "parses with format-string '%z'" do
      assert Datix.strptime("+0010", "%z") == {:ok, %{zone_offset: 600}}
      assert Datix.strptime("+1000", "%z") == {:ok, %{zone_offset: 36_000}}
      assert Datix.strptime("-0010", "%z") == {:ok, %{zone_offset: -600}}
      assert Datix.strptime("-1000", "%z") == {:ok, %{zone_offset: -36_000}}
      assert Datix.strptime("+0000", "%z") == {:ok, %{zone_offset: 0}}
      assert Datix.strptime("-0000", "%z") == {:ok, %{zone_offset: 0}}
    end

    test "returns error tuple for invalid value for modifier %z" do
      assert Datix.strptime("foo", "%z") == {:error, {:invalid_integer, [modifier: "%z"]}}
    end

    # %Z - Time zone abbreviation

    test "parses with format-string '%Z'" do
      assert Datix.strptime("CEST", "%Z") == {:ok, %{zone_abbr: "CEST"}}
      assert Datix.strptime("    CEST", "%Z") == {:ok, %{zone_abbr: "CEST"}}
    end

    test "returns error tuple for invalid value for modifier %Z" do
      assert Datix.strptime("foo", "%Z") == {:error, {:invalid_string, [modifier: "%Z"]}}
    end

    # %% - Literal "%" character

    test "parses with format-string '%%'" do
      assert Datix.strptime("%", "%%") == {:ok, %{}}
      assert Datix.strptime("ab%cd", "ab%%cd") == {:ok, %{}}
    end

    # Format-string combinations

    test "parses with format-string '%Y-%m-%d %H:%M:%S'" do
      assert Datix.strptime("2018-10-17 12:34:56", "%Y-%m-%d %H:%M:%S") ==
               {:ok, %{day: 17, hour: 12, minute: 34, month: 10, second: 56, year: 2018}}
    end

    test "parses with format-string '%A, %x'" do
      assert Datix.strptime("Wednesday, 2018-10-17", "%A, %x") ==
               {:ok, %{day: 17, month: 10, year: 2018, day_of_week: 3}}
    end

    test "parses with format-string '%d/%Y'" do
      assert Datix.strptime("03/1234", "%d/%Y") == {:ok, %{day: 3, year: 1234}}
    end

    test "parses with format-string '%-d/%-Y'" do
      assert Datix.strptime("3/1234", "%-d/%-Y") == {:ok, %{day: 3, year: 1234}}
    end

    test "parses with format-string '%B %-d, %Y'" do
      assert Datix.strptime("April 2, 2020", "%B %-d, %Y") ==
               {:ok, %{day: 2, month: 4, year: 2020}}
    end

    test "parses with format-string '%A, %a'" do
      assert Datix.strptime("Friday, Fri", "%A, %a") == {:ok, %{day_of_week: 5}}
    end

    # Conflicting data

    test "returns error tuple for conflicting days of week" do
      assert Datix.strptime("Wednesday, Fri", "%A, %a") ==
               {:error, {:conflict, [expected: 3, got: 5, modifier: "%a"]}}
    end

    test "returns error tuple for conflicting days" do
      assert Datix.strptime("02, 03", "%d, %d") ==
               {:error, {:conflict, [expected: 2, got: 3, modifier: "%d"]}}
    end

    test "returns error tuple for conflicting am/pm" do
      assert Datix.strptime("AM, pm", "%p, %P") ==
               {:error, {:conflict, [expected: :am, got: :pm, modifier: "%P"]}}
    end
  end

  describe "parse!/3" do
    test "raisee an error for an invalid sting" do
      msg = "invalid string for %a"

      assert_raise ArgumentError, msg, fn ->
        Datix.strptime!("Xan", "%a")
      end
    end

    test "raisee an error for an invalid integer" do
      msg = "invalid integer for %d"

      assert_raise ArgumentError, msg, fn ->
        Datix.strptime!("1X", "%d")
      end
    end

    test "raisee an error for an invalid input" do
      msg = "invalid input"

      assert_raise ArgumentError, msg, fn ->
        Datix.strptime!("10a", "%d")
      end
    end

    test "raisee an error for a parse error" do
      msg = ~s|parse error: expected "b", got "a"|

      assert_raise ArgumentError, msg, fn ->
        Datix.strptime!("a", "b")
      end
    end

    test "raises an error for conflicting data" do
      msg = "expected 3, got 5 for %a"

      assert_raise ArgumentError, msg, fn ->
        Datix.strptime!("Wednesday, Fri", "%A, %a")
      end
    end
  end
end
