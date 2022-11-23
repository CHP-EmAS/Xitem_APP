import 'dart:io';

import 'package:de/controllers/ApiController.dart';

class PublicUser {
  PublicUser(this.userID, this.name, this.birthday, this.role, this.avatar);

  final String userID;
  String name;

  DateTime birthday;

  String role;
  File avatar;

  reload() async {
    PublicUser reloadedUser = await Api.loadPublicUserInformation(userID);

    if (reloadedUser == null) {
      print("Error while reloading User: " + this.userID);
      return;
    }

    this.name = reloadedUser.name;
    this.birthday = reloadedUser.birthday;
    this.role = reloadedUser.role;
    this.avatar = reloadedUser.avatar;
  }
}

class AppUser {
  AppUser(this.userID, this.name, this.email, this.birthday, this.role, this.registeredAt, this.avatar);

  final String userID;
  String email;
  String name;

  DateTime birthday;
  DateTime registeredAt;

  String role;
  File avatar;

  reload() async {
    AppUser reloadedUser = await Api.loadAppUserInformation(userID);

    if (reloadedUser == null) {
      print("Error while reloading User: " + this.userID);
      return;
    }

    this.name = reloadedUser.name;
    this.email = reloadedUser.email;
    this.birthday = reloadedUser.birthday;
    this.registeredAt = reloadedUser.registeredAt;
    this.role = reloadedUser.role;
    this.avatar = reloadedUser.avatar;
  }
}
