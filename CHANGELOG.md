# Changelog

## 0.3.3 - 2026/01/13

+ Require Elixir 1.15 or later.
+ Fix warning for an unpined variable.

## 0.3.2 - 2024/07/16

+ Fix range argument for `String.slice/2` to avoid warnings.

## 0.3.1 - 2022/08/09

+ Allow missing leading zeros in most integer modifiers.

## 0.3.0 - 2022/08/04

### Breaking changes

+ All `:error` tuples now contain an exception struct.
+ Add option `:time_zone` for `Datix.DateTime.parse/3` and
  `Datix.Datetime.parse!/3`.
+ Update return value of `Datix.DateTime.parse/3`. Returns now an `:ok` tuples
  with the parsed `DateTime` or an `:error` tuple with an exception struct.
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
