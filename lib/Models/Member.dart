import 'package:de/Controllers/ApiController.dart';
import 'package:de/Controllers/UserController.dart';
import 'package:de/Interfaces/api_interfaces.dart';

class AssociatedUser {
  AssociatedUser(this.calendarID, this.userID, this.isOwner, this.canCreateEvents, this.canEditEvents) {
    UserController.loadPublicUser(userID);

    if (userID == UserController.user.userID) {
      UserController.calendarList[calendarID].isOwner = this.isOwner;
      UserController.calendarList[calendarID].canCreateEvents = this.canCreateEvents;
      UserController.calendarList[calendarID].canEditEvents = this.canEditEvents;
    }
  }

  final String calendarID;
  final String userID;
  bool isOwner;
  bool canCreateEvents;
  bool canEditEvents;

  reload() async {
    AssociatedUser reloadedMember = await Api.loadAssociatedUser(calendarID, userID);

    if (reloadedMember == null) return;

    if (this.userID != reloadedMember.userID) {
      print("Unexpected Error when reloading Member, IDs not equal!");
      return;
    }

    this.isOwner = reloadedMember.isOwner;
    this.canCreateEvents = reloadedMember.canCreateEvents;
    this.canEditEvents = reloadedMember.canEditEvents;

    if (userID == UserController.user.userID) {
      UserController.calendarList[calendarID].isOwner = this.isOwner;
      UserController.calendarList[calendarID].canCreateEvents = this.canCreateEvents;
      UserController.calendarList[calendarID].canEditEvents = this.canEditEvents;
    }

    return;
  }

  Future<bool> changePermissions(bool isOwner, bool canCreateEvents, bool canEditEvents) async {
    if (await Api.patchAssociatedUser(calendarID, userID, PatchAssociatedUserRequest(isOwner, canCreateEvents, canEditEvents))) {
      await reload();
      return true;
    }

    return false;
  }
}
