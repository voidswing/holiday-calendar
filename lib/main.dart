import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jenz_calendar/utils.dart';
import 'package:url_launcher/url_launcher.dart';

const BOX_NAME = "jenzCalendar";

late Box box;
late double deviceWidth;
late double deviceHeight;

void main() async {
  await Hive.initFlutter();
  box = await Hive.openBox<dynamic>(BOX_NAME);

  runApp(const JenzCalendarApp());
}

class JenzCalendarApp extends StatelessWidget {
  const JenzCalendarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '공휴일 달력',
      home: MyApp(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ko', 'KR'),
      ],
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Timer _timer;

  late DateTime now;
  late String currentDateString;
  late int year;
  late int month;
  late int day;

  late String currentWeekday;
  late int monthWeekNumber;
  late int yearWeekNumber;

  Future<int>? _remainingHolidaysInMonth;
  int? _remainingDaysInMonth;
  int? _remainingBusinessDaysInMonth;

  Future<int>? _remainingHolidaysInYear;
  int? _remainingDaysInYear;
  int? _remainingBusinessDaysInYear;

  Widget getCalendarContainer(List<TextSpan> textSpans, double deviceHeight, double deviceWidth) {
    return Container(
      width: max(deviceWidth * 0.5, 300),
      padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.05, vertical: deviceHeight * 0.05),
      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 5.0)),
      child: Column(
        children: textSpans
            .map((textSpan) => Column(
                  children: [
                    SizedBox(height: deviceHeight * 0.02),
                    Text.rich(
                      textSpan,
                      style: TextStyle(
                        fontSize: deviceHeight * 0.02,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: deviceHeight * 0.01),
                  ],
                ))
            .toList(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    now = DateTime.now();

    DateTime? userDateTime = box.get("userDateTime");

    if (userDateTime != null) {
      now = DateTime(
        userDateTime.year,
        userDateTime.month,
        userDateTime.day,
        now.hour,
        now.minute,
        now.second,
      );
    }

    year = now.year;
    month = now.month;
    day = now.day;

    currentDateString = getDateTimeString(now);
    currentWeekday = getWeekdayString(now);

    DateTime nowWithoutTime = DateTime(now.year, now.month, now.day);

    // month
    monthWeekNumber = getMonthWeekNumber(now);
    _remainingDaysInMonth = DateTime(now.year, now.month + 1, 1).difference(nowWithoutTime).inDays;
    _remainingHolidaysInMonth = remainingHolidaysInCurrentMonth(now);

    // year
    yearWeekNumber = getYearWeekNumber(now);
    DateTime lastDayOfYear = DateTime(now.year, 12, 31);
    _remainingDaysInYear = lastDayOfYear.difference(nowWithoutTime).inDays + 1;
    _remainingHolidaysInYear = remainingHolidaysInCurrentYear(now);

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        now = DateTime.now();

        DateTime? userDateTime = box.get("userDateTime");

        if (userDateTime != null) {
          now = DateTime(
            userDateTime.year,
            userDateTime.month,
            userDateTime.day,
            now.hour,
            now.minute,
            now.second,
          );
        }

        currentDateString = getDateTimeString(now);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2001, 1),
      lastDate: DateTime(2040, 12),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 41, 127, 129),
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null && picked != now) {
      setState(() {
        DateTime newDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
          now.second,
        );

        box.put("userDateTime", newDate);

        now = newDate;

        year = now.year;
        month = now.month;
        day = now.day;

        currentDateString = getDateTimeString(now);
        currentWeekday = getWeekdayString(now);

        DateTime nowWithoutTime = DateTime(now.year, now.month, now.day);
        // month
        monthWeekNumber = getMonthWeekNumber(now);
        _remainingDaysInMonth = DateTime(now.year, now.month + 1, 1).difference(nowWithoutTime).inDays;
        _remainingHolidaysInMonth = remainingHolidaysInCurrentMonth(now);

        // year
        yearWeekNumber = getYearWeekNumber(now);
        DateTime lastDayOfYear = DateTime(now.year, 12, 31);

        _remainingDaysInYear = lastDayOfYear.difference(nowWithoutTime).inDays + 1;
        _remainingHolidaysInYear = remainingHolidaysInCurrentYear(now);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 50, 87),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: deviceHeight * 0.05),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  iconSize: deviceHeight * 0.06,
                  color: Colors.white,
                  onPressed: () {
                    _selectDate(context);
                  },
                ),
                SizedBox(height: deviceHeight * 0.05),
                getCalendarContainer([
                  const TextSpan(text: "오늘은", style: TextStyle(color: Colors.white)),
                  TextSpan(text: currentDateString, style: const TextStyle(color: Colors.white)),
                  TextSpan(text: currentWeekday, style: const TextStyle(color: Colors.white)),
                ], deviceHeight, deviceWidth),
                SizedBox(height: deviceHeight * 0.06),
                FutureBuilder(
                  future: _remainingHolidaysInMonth,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      int remainingHolidaysInMonth = snapshot.data!;
                      _remainingBusinessDaysInMonth = _remainingDaysInMonth! - remainingHolidaysInMonth;

                      return getCalendarContainer([
                        TextSpan(text: "$year년 $month월 $day일은", style: const TextStyle(color: Colors.white)),
                        TextSpan(
                          children: [
                            TextSpan(text: "$month월 $monthWeekNumber주차", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const TextSpan(),
                        TextSpan(
                          children: [
                            const TextSpan(text: "이번달 남은 날: ", style: TextStyle(color: Colors.white70)),
                            TextSpan(text: "$_remainingDaysInMonth", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        TextSpan(
                          children: [
                            const TextSpan(text: "이번달 남은 휴일 수: ", style: TextStyle(color: Colors.white70)),
                            TextSpan(text: "$remainingHolidaysInMonth", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        TextSpan(
                          children: [
                            const TextSpan(text: "이번달 남은 영업일 수: ", style: TextStyle(color: Colors.white70)),
                            TextSpan(text: "$_remainingBusinessDaysInMonth", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ], deviceHeight, deviceWidth);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
                SizedBox(height: deviceHeight * 0.05),
                FutureBuilder(
                  future: _remainingHolidaysInYear,
                  builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      int remainingHolidaysInYear = snapshot.data!;
                      _remainingBusinessDaysInYear = _remainingDaysInYear! - remainingHolidaysInYear;

                      return getCalendarContainer([
                        TextSpan(text: "$year년 $month월 $day일은", style: const TextStyle(color: Colors.white)),
                        TextSpan(
                          children: [
                            TextSpan(text: "$year년 $yearWeekNumber 주차", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        const TextSpan(),
                        TextSpan(
                          children: [
                            const TextSpan(text: "올해 남은 날: ", style: TextStyle(color: Colors.white70)),
                            TextSpan(text: "$_remainingDaysInYear", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        TextSpan(
                          children: [
                            const TextSpan(text: "올해 남은 휴일 수: ", style: TextStyle(color: Colors.white70)),
                            TextSpan(text: "$remainingHolidaysInYear", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        TextSpan(
                          children: [
                            const TextSpan(text: "올해 남은 영업일 수: ", style: TextStyle(color: Colors.white70)),
                            TextSpan(text: "$_remainingBusinessDaysInYear", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ], deviceHeight, deviceWidth);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
                SizedBox(height: deviceHeight * 0.2),
                GestureDetector(
                  onTap: () {
                    const String repositoryUrl = "https://github.com/jenz0000/holiday-calendar";
                    launchUrl(Uri.parse(repositoryUrl));
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click, // 마우스 포인터 스타일을 클릭으로 변경
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/github.png',
                          width: 24.0,
                          height: 24.0,
                        ),
                        const SizedBox(width: 4.0),
                        const Text(
                          "GitHub Repository",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
