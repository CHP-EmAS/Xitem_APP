import 'dart:io';

import 'package:flutter/material.dart';

class PublicHoliday {
  final String name;
  final DateTime date;

  PublicHoliday(this.name, this.date);
}

class Birthday {
  final File? avatar;
  final String? localID;

  final String name;
  final DateTime birthday;


  Birthday({required this.name, required this.birthday, this.avatar, this.localID});

  int getAgeInYear(int year) {
    return year - birthday.year;
  }

  DateTime nextBirthday() {
    DateTime now = DateTime.now();
    DateTime convertedBirthday = DateTime(now.year, birthday.month, birthday.day);

    if (convertedBirthday.isBefore(now.subtract(const Duration(days: 1)))) {
      convertedBirthday = DateTime(now.year + 1, convertedBirthday.month, convertedBirthday.day);
    }

    return convertedBirthday;
  }
}