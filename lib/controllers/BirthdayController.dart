import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xitem/controllers/UserController.dart';
import 'package:xitem/models/SpecialEvent.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class BirthdayController {
  bool _isInitialized = false;
  final UserController _userController;

  final List<Birthday> _remoteBirthdays = [];

  static const _birthdayFileName = 'birthdays.json';
  late File _birthdayFile;
  final List<LocalBirthday> _localBirthdays = [];

  BirthdayController(this._userController);

  Future<ResponseCode> initialize() async {
    _birthdayFile = await _initBirthdayFile();

    ResponseCode loadStateHolidays = await generateRemoteBirthdayList();
    if (loadStateHolidays != ResponseCode.success) {
      return loadStateHolidays;
    }

    _localBirthdays.addAll(await _loadBirthdaysFromLocalStorage());

    _isInitialized = true;
    return ResponseCode.success;
  }

  Future<ResponseCode> generateRemoteBirthdayList() async {
    _remoteBirthdays.clear();

    _remoteBirthdays.addAll(_loadBirthdaysFromMember());

    return ResponseCode.success;
  }

  List<Birthday> birthdays() {
    if(!_isInitialized) {
      throw AssertionError("BirthdayController must be initialized before it can be accessed!");
    }

    List<Birthday> allBirthdays = [..._remoteBirthdays, ..._localBirthdays.map((e) => Birthday(name: e.name, birthday: e.birthday, localID: e.id))];
    allBirthdays.sort(_birthdaySorter);

    return allBirthdays;
  }

  Future<void> addBirthdayToLocalStorage(LocalBirthday birthday) async {
    if(!_isInitialized) {
      throw AssertionError("BirthdayController must be initialized before it can be accessed!");
    }

    _localBirthdays.add(birthday);

    await _overwriteLocalBirthdayFile();
  }

  Future<void> removeBirthdayFromLocalStorage(String birthdayId) async {
    if(!_isInitialized) {
      throw AssertionError("BirthdayController must be initialized before it can be accessed!");
    }

   _localBirthdays.removeWhere((element) => element.id == birthdayId);

    await _overwriteLocalBirthdayFile();
  }

  List<Birthday> _loadBirthdaysFromMember() {
    List<Birthday> memberBirthdays = [];

    for (User user in _userController.getUserList()) {
      DateTime? birthday = user.birthday;

      if (birthday == null) {
        continue;
      }

      Birthday newBirthday = Birthday(name: user.name, birthday: birthday, avatar: user.avatar);
      memberBirthdays.add(newBirthday);
    }

    return memberBirthdays;
  }

  Future<List<LocalBirthday>> _loadBirthdaysFromLocalStorage() async {
    final List<LocalBirthday> localBirthdays = [];

    try {
      final content = await _birthdayFile.readAsString();

      final List<dynamic> jsonData = jsonDecode(content);

      for (Map<String, dynamic> data in jsonData) {
        LocalBirthday? loadedBirthday = LocalBirthday.fromJson(data);

        if(loadedBirthday != null) {
          localBirthdays.add(loadedBirthday);
        }
      }
    } catch(e) {
      debugPrint(e.toString());
    }

    return localBirthdays;
  }

  Future<void> _overwriteLocalBirthdayFile() async {
    final jsonList = _localBirthdays.map((e) => e.toJson()).toList();
    await _birthdayFile.writeAsString(jsonEncode(jsonList));
  }

  int _birthdaySorter(Birthday a, Birthday b) {
    DateTime nextBirthdayA = a.nextBirthday();
    DateTime nextBirthdayB = b.nextBirthday();

    if (nextBirthdayA == nextBirthdayB) {
      return 0;
    } else if (nextBirthdayA.isAfter(nextBirthdayB)) {
      return 1;
    } else {
      return -1;
    }
  }

  static Future<File> _initBirthdayFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final localPath = directory.path;
    return File('$localPath/$_birthdayFileName');
  }
}

class LocalBirthday {
  static const uuid = Uuid();

  final String id;
  final String name;
  final DateTime birthday;

  LocalBirthday(this.name, this.birthday)
      : id = uuid.v4();

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "birthday": birthday.toString(),
    };
  }

  static LocalBirthday? fromJson(Map<String, dynamic> data) {
    if(!data.containsKey("name") || !data.containsKey("birthday")) {
      return null;
    }

    LocalBirthday? jsonBirthday;

    try {
      jsonBirthday = LocalBirthday(data["name"], DateTime.parse(data["birthday"]));
    } catch (error) {
      debugPrint(error.toString());
    }

    return jsonBirthday;
  }
}
