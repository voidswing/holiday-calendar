import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String getDateTimeString(DateTime date) {
  final DateFormat dateFormat = DateFormat('yyyy년 M월 d일 HH시 mm분 ss초', 'ko_KR');
  final String formattedDate = dateFormat.format(date);
  return formattedDate;
}

String getWeekdayString(DateTime date) {
  final DateFormat weekdayFormat = DateFormat.EEEE('ko_KR');
  final String formattedWeekday = weekdayFormat.format(date);

  return formattedWeekday;
}

int getMonthWeekNumber(DateTime date) {
  date = DateTime(date.year, date.month, date.day);

  DateTime firstDayOfMonth = DateTime(date.year, date.month, 1);
  DateTime firstThursdayOfMonth;

  if (firstDayOfMonth.weekday <= DateTime.thursday) {
    firstThursdayOfMonth = firstDayOfMonth.add(Duration(days: DateTime.thursday - firstDayOfMonth.weekday));
  } else {
    firstThursdayOfMonth = firstDayOfMonth.add(Duration(days: DateTime.thursday + 7 - firstDayOfMonth.weekday));
  }

  DateTime thursdayOfWeek = date.add(Duration(days: DateTime.thursday - date.weekday));

  if (thursdayOfWeek.isBefore(firstThursdayOfMonth)) {
    return 1;
  }

  int daysBetween = thursdayOfWeek.difference(firstThursdayOfMonth).inDays;
  return (daysBetween / 7).floor() + 1;
}

int getYearWeekNumber(DateTime currentDate) {
  currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

  DateTime firstDayOfYear = DateTime(currentDate.year, 1, 1);

  DateTime firstMondayOfYear;
  if (firstDayOfYear.weekday == DateTime.monday) {
    firstMondayOfYear = firstDayOfYear;
  } else if (firstDayOfYear.weekday < DateTime.monday) {
    firstMondayOfYear = firstDayOfYear.subtract(Duration(days: firstDayOfYear.weekday - DateTime.monday));
  } else {
    firstMondayOfYear = firstDayOfYear.add(Duration(days: DateTime.monday + 7 - firstDayOfYear.weekday));
  }

  int daysBetween = currentDate.difference(firstMondayOfYear).inDays;
  int yearWeekNumber = (daysBetween / 7).floor() + 1;

  return yearWeekNumber;
}

Future<bool> isHoliday(DateTime date) async {
  bool isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  if (isWeekend) {
    return true;
  }

  String filePath = 'holidays/${date.year}.json';
  String jsonString = await rootBundle.loadString(filePath);
  Map<String, dynamic> holidays = jsonDecode(jsonString);

  String dateString = DateFormat('yyyy-MM-dd').format(date);

  return holidays.containsKey(dateString);
}

Future<int> remainingHolidaysInCurrentMonth(DateTime currentDate) async {
  currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

  int remainingHolidays = 0;
  DateTime firstDayOfNextMonth;

  if (currentDate.month == 12) {
    firstDayOfNextMonth = DateTime(currentDate.year + 1, 1, 1);
  } else {
    firstDayOfNextMonth = DateTime(currentDate.year, currentDate.month + 1, 1);
  }

  DateTime lastDayOfCurrentMonth = firstDayOfNextMonth.subtract(const Duration(days: 1));

  DateTime startDate = currentDate;

  for (DateTime date = startDate; date.isBefore(lastDayOfCurrentMonth.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
    bool isHolidayToday = await isHoliday(date);
    if (isHolidayToday) {
      remainingHolidays++;
    }
  }

  return remainingHolidays;
}

Future<int> remainingHolidaysInCurrentYear(DateTime currentDate) async {
  currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

  int remainingHolidays = 0;

  DateTime firstDayOfYear = DateTime(currentDate.year, 1, 1);

  DateTime lastDayOfYear = DateTime(currentDate.year + 1, 1, 1).subtract(const Duration(days: 1));

  DateTime startDate = currentDate.isBefore(firstDayOfYear) ? firstDayOfYear : currentDate;

  for (DateTime date = startDate; date.isBefore(lastDayOfYear.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
    bool isHolidayToday = await isHoliday(date);
    if (isHolidayToday) {
      remainingHolidays++;
    }
  }

  return remainingHolidays;
}
