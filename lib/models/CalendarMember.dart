class CalendarMember {
  CalendarMember(this.calendarID, this.userID, this.isOwner, this.canCreateEvents, this.canEditEvents);
    //UserController.loadPublicUser(userID);

    // if (userID == UserController.user.userID) {
    //   UserController.calendarList[calendarID].isOwner = this.isOwner;
    //   UserController.calendarList[calendarID].canCreateEvents = this.canCreateEvents;
    //   UserController.calendarList[calendarID].canEditEvents = this.canEditEvents;
    // }


  final String calendarID;
  final String userID;
  final bool isOwner;
  final bool canCreateEvents;
  final bool canEditEvents;
}
