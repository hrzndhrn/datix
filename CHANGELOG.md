# Changelog

## 0.3.0 - 2022/08/03

### Breaking changes

+ Add option `pivot_year`. This option is required if the format string contains
  `%y` (year as 2-digits).

## 0.2.0 - 2022/08/02

+ Add `Datix.compile/1` and `Datix.compile!/1`. These return a "compiled" format
  that can be now passed to `Datix.strptime/3` and other functions.
+ Fix a bug with `Datix.DateTime.parse/3` when parsing strings with a timezone
  abbreviation but no timezone offset.

## 0.1.1 - 2020/01/15

+ Fix parsing of times in 12-hour-system.

## 0.1.0 - 2021/01/14

+ The very first version.
