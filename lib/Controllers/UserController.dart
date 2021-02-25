import 'dart:io';

import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/HolidayListController.dart';
import 'package:de/Controllers/NavigationController.dart';
import 'package:de/Interfaces/api_interfaces.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/User.dart';
import 'package:flutter/cupertino.dart';

import 'file:///C:/Users/Clemens/Documents/Development/AndroidStudioProjects/xitem/lib/Settings/locator.dart';

class UserController {
  static final NavigationService _navigationService = locator<NavigationService>();

  static AppUser user;

  static PublicUser unknownUser = new PublicUser("0", "Unbekannt", null, "Unbekannt", null);

  static Map<String, Calendar> calendarList = new Map<String, Calendar>();
  static Map<String, PublicUser> publicUserList = new Map<String, PublicUser>();

  static Future<bool> trySecureLogin() async {
    final String userID = await Api.secureLogin();
    if (userID == null) return false;

    AppUser loadedUser = await Api.loadAppUserInformation(userID);
    if (loadedUser == null) return false;

    UserController.user = loadedUser;
    return true;
  }

  static Future<bool> login(String email, String password) async {
    final String userID = await Api.login(UserLoginRequest(email, password));
    if (userID == null) return false;

    AppUser loadedUser = await Api.loadAppUserInformation(userID);
    if (loadedUser == null) return false;

    UserController.user = loadedUser;
    return true;
  }

  static Future<void> logout() async {
    await Api.logout();

    user = null;
    calendarList.clear();
    publicUserList.clear();

    _navigationService.pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  static Future<bool> changeUserInformation(String name, DateTime birthday) async {
    if (UserController.user == null) return false;

    if (await Api.patchUser(user.userID, PatchUserRequest(name, birthday))) {
      user.name = name;
      user.birthday = birthday;

      return true;
    }

    return false;
  }

  static Future<bool> changeAvatar(File avatarImage) async {
    if (UserController.user == null) return false;

    if (await Api.pushAvatarToServer(avatarImage, user.userID)) {
      user.avatar = avatarImage;
      return true;
    }

    return false;
  }

  static Future<bool> loadAllCalendars() async {
    print("Loading Calendarlist...");

    if (UserController.user != null) {
      await HolidayController.loadPublicHolidays();

      List<Calendar> loadedCalendarList = await Api.loadAssociatedCalendars(user.userID);
      if (loadedCalendarList != null) {
        UserController.calendarList.clear();

        for (final calendar in loadedCalendarList) {
          UserController.calendarList[calendar.id] = calendar;
          await calendar.loadAssociatedUsers();
          await calendar.loadCurrentEvents();
          await calendar.loadAllVotings();
          await calendar.loadAllNotes();
        }

        return true;
      }
    }

    return false;
  }

  static Future<String> createCalendar(String name, String password, bool canJoin, Color color, IconData icon) async {
    if (UserController.user != null) {
      String calendarID = await Api.createCalendar(CreateCalendarRequest(name, password, canJoin, color, icon));
      if (calendarID == null) return null;

      Calendar newCalendar = await Api.loadSingleCalendar(calendarID);
      if (newCalendar == null) return null;

      UserController.calendarList[newCalendar.id] = newCalendar;
      await newCalendar.loadAssociatedUsers();

      return newCalendar.name + "#" + newCalendar.hash;
    }

    return null;
  }

  static Future<bool> joinCalendar(String hashName, String password, Color color, IconData icon) async {
    if (UserController.user != null) {
      String calendarID = await Api.joinCalendar(hashName, JoinCalendarRequest(password, color, icon));
      if (calendarID == null) return false;

      Calendar newCalendar = await Api.loadSingleCalendar(calendarID);
      if (newCalendar == null) return false;

      UserController.calendarList[newCalendar.id] = newCalendar;
      await newCalendar.loadAssociatedUsers();

      return true;
    }

    return false;
  }

  static Future<bool> acceptCalendarInvitation(String invToken, Color color, IconData icon) async {
    if (UserController.user != null) {
      String calendarID = await Api.acceptCalendarInvitationToken(AcceptCalendarInvitationRequest(invToken, color, icon));
      if (calendarID == null) return false;

      Calendar newCalendar = await Api.loadSingleCalendar(calendarID);
      if (newCalendar == null) return false;

      UserController.calendarList[newCalendar.id] = newCalendar;
      await newCalendar.loadAssociatedUsers();

      return true;
    }

    return false;
  }

  static Future<bool> deleteCalendar(String calendarID, String userPassword) async {
    if (UserController.user != null) {
      if (!await Api.checkHashPassword(userPassword)) return false;

      if (!await Api.deleteCalendar(calendarID)) return false;

      calendarList.remove(calendarID);
      return true;
    }

    return false;
  }

  static Future<bool> leaveCalendar(String calendarID, String userPassword) async {
    if (UserController.user != null) {
      if (!await Api.checkHashPassword(userPassword)) return false;

      if (!await Api.leaveCalendar(calendarID)) return false;

      calendarList.remove(calendarID);
      return true;
    }

    return false;
  }

  static void loadPublicUser(String userID) async {
    if (userID == UserController.user.userID) return;

    if (!publicUserList.containsKey(userID)) {
      PublicUser loadedPublicUser = await Api.loadPublicUserInformation(userID);

      if (loadedPublicUser == null) return null;

      publicUserList[userID] = loadedPublicUser;
    }
  }

  static PublicUser getPublicUserInformation(String userID) {
    if (userID == UserController.user.userID) {
      return new PublicUser(userID, UserController.user.name, UserController.user.birthday, UserController.user.role, UserController.user.avatar);
    }

    if (!publicUserList.containsKey(userID)) {
      loadPublicUser(userID);
      return null;
    }

    return publicUserList[userID];
  }
}
