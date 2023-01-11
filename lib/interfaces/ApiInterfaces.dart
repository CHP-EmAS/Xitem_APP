abstract class ApiRequestData {
  Map<String, dynamic> toJson();
}

class UserLoginRequest extends ApiRequestData {
  UserLoginRequest(this._email, this.password);

  final String _email;
  final String password;

  @override
  Map<String, dynamic> toJson() => {
        'email': _email,
        'password': password,
      };
}

class UserRegistrationRequest extends ApiRequestData {
  UserRegistrationRequest(this._email, this._name, this._birthday);

  final String _email;
  final String _name;

  final DateTime? _birthday;

  @override
  Map<String, dynamic> toJson() {

    if (_birthday != null) {
      return {
        'email': _email,
        'name': _name,
        'birthday': _birthday!.toIso8601String(),
      };
    }

    return {
      'email': _email,
      'name': _name,
    };
  }
}

class ChangePasswordRequest extends ApiRequestData {
  ChangePasswordRequest(this._oldPassword, this._newPassword, this._repeatPassword);

  final String _oldPassword;
  final String _newPassword;
  final String _repeatPassword;

  @override
  Map<String, dynamic> toJson() => {
        'old_password': _oldPassword,
        'new_password': _newPassword,
        'repeat_password': _repeatPassword,
      };
}

class PatchUserRequest extends ApiRequestData {
  PatchUserRequest(this._name, this._birthday);

  final String _name;
  final DateTime? _birthday;

  @override
  Map<String, dynamic> toJson() => {
        'name': _name,
        'birthday': _birthday?.toIso8601String(),
      };
}

class PatchCalendarMemberRequest extends ApiRequestData {
  PatchCalendarMemberRequest(this._isOwner, this._canCreateEvents, this._canEditEvents);

  final bool _isOwner;
  final bool _canCreateEvents;
  final bool _canEditEvents;

  @override
  Map<String, dynamic> toJson() => {'is_owner': _isOwner, 'can_create_events': _canCreateEvents, 'can_edit_events': _canEditEvents};
}

class CreateEventRequest extends ApiRequestData {
  CreateEventRequest(this._beginDate, this._endDate, this._title, this._daylong, this._description, this._color);

  final DateTime _beginDate;
  final DateTime _endDate;

  final String _title;
  final String _description;

  final bool _daylong;
  final int _color;

  @override
  Map<String, dynamic> toJson() => {
        'begin_date': _beginDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'title': _title,
        'description': _description,
        'daylong': _daylong,
        'color': _color,
      };
}

class PatchEventRequest extends ApiRequestData {
  PatchEventRequest(this._beginDate, this._endDate, this._title, this._daylong, this._description, this._color);

  final DateTime _beginDate;
  final DateTime _endDate;

  final String _title;
  final String _description;

  final bool _daylong;
  final int _color;

  @override
  Map<String, dynamic> toJson() => {
        'begin_date': _beginDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'title': _title,
        'description': _description,
        'daylong': _daylong,
        'color': _color,
      };
}

class CreateNoteRequest extends ApiRequestData {
  CreateNoteRequest(this._title, this._content, this._pinned, this._color);

  final String _title;
  final String _content;

  final bool _pinned;
  final int _color;

  @override
  Map<String, dynamic> toJson() => {
        'title': _title,
        'content': _content,
        'pinned': _pinned,
        'color': _color,
      };
}

class PatchNoteRequest extends ApiRequestData {
  PatchNoteRequest(this._title, this._content, this._pinned, this._color);

  final String _title;
  final String _content;

  final bool _pinned;
  final int _color;

  @override
  Map<String, dynamic> toJson() => {
        'title': _title,
        'content': _content,
        'pinned': _pinned,
        'color': _color,
      };
}

class LoadSingleCalendarResponse {
  LoadSingleCalendarResponse.fromJson(Map<String, dynamic> data) {
    if(!data.containsKey("Calendar")) {
      throw ArgumentError("Missing JSON field 'Calendar'!");
    }

    Map<String, dynamic> calendar = data["Calendar"];

    if(!calendar.containsKey("calendarObject") || !calendar.containsKey("color") || !calendar.containsKey("icon")) {
      throw ArgumentError("Missing JSON field in 'Calendar': 'calendarObject' or 'color' or 'icon'!");
    }

    color = int.parse(calendar["color"]);
    iconPoint = int.parse(calendar["icon"]);

    Map<String, dynamic> calendarObject = calendar["calendarObject"];

    if(!calendarObject.containsKey("calendar_id") || !calendarObject.containsKey("calendar_name") || !calendarObject.containsKey("can_join") || !calendarObject.containsKey("creation_date")) {
      throw ArgumentError("Missing JSON field 'calendar_id' or 'calendar_name' or 'can_join' or 'creation_date'!");
    }

    id = calendar["calendarObject"]["calendar_id"];
    fullName = calendar["calendarObject"]["calendar_name"];
    canJoin = calendar["calendarObject"]["can_join"];
    creationDate = calendar["calendarObject"]["creation_date"];
  }

  late final String id;
  late final String fullName;
  late final bool canJoin;
  late final String creationDate;
  //final bool isOwner = calendar["is_owner"];
  //final bool canCreateEvents = calendar["can_create_events"];
  //final bool canEditEvents = calendar["can_edit_events"];
  late final int color;
  late final int iconPoint;
}


