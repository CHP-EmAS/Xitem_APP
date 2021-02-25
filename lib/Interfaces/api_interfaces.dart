import 'package:de/Models/Voting.dart';
import 'package:flutter/cupertino.dart';

abstract class ApiRequestData {
  Map<String, dynamic> toJson();
}

class UserLoginRequest extends ApiRequestData {
  UserLoginRequest(this._email, this.password);

  final String _email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': _email,
        'password': password,
      };
}

class UserRegistrationRequest extends ApiRequestData {
  UserRegistrationRequest(this._email, this._name, this._birthday);

  final String _email;
  final String _name;

  final DateTime _birthday;

  Map<String, dynamic> toJson() {
    if (_birthday == null) {
      return {
        'email': _email,
        'name': _name,
      };
    }

    return {
      'email': _email,
      'name': _name,
      'birthday': _birthday.toIso8601String(),
    };
  }
}

class ChangePasswordRequest extends ApiRequestData {
  ChangePasswordRequest(this._oldPassword, this._newPassword, this._repeatPassword);

  final String _oldPassword;
  final String _newPassword;
  final String _repeatPassword;

  Map<String, dynamic> toJson() => {
        'old_password': _oldPassword,
        'new_password': _newPassword,
        'repeat_password': _repeatPassword,
      };
}

class PatchUserRequest extends ApiRequestData {
  PatchUserRequest(this._name, this._birthday);

  final String _name;
  final DateTime _birthday;

  Map<String, dynamic> toJson() => {
        'name': _name,
        'birthday': _birthday?.toIso8601String(),
      };
}

class CreateCalendarRequest extends ApiRequestData {
  CreateCalendarRequest(this._title, this._password, this._canJoin, Color color, IconData icon)
      : this._color = color.value,
        this._icon = icon.codePoint;

  final String _title;
  final String _password;

  final bool _canJoin;
  final int _color;

  final int _icon;

  Map<String, dynamic> toJson() => {
        'title': _title,
        'password': _password,
        'can_join': _canJoin,
        'color': _color,
        'icon': _icon,
      };
}

class JoinCalendarRequest extends ApiRequestData {
  JoinCalendarRequest(this._password, Color color, IconData icon)
      : this._color = color.value,
        this._icon = icon.codePoint;

  final String _password;
  final int _color;
  final int _icon;

  Map<String, dynamic> toJson() => {'password': _password, 'color': _color, 'icon': _icon};
}

class PatchAssociatedUserRequest extends ApiRequestData {
  PatchAssociatedUserRequest(this._isOwner, this._canCreateEvents, this._canEditEvents);

  final bool _isOwner;
  final bool _canCreateEvents;
  final bool _canEditEvents;

  Map<String, dynamic> toJson() => {'is_owner': _isOwner, 'can_create_events': _canCreateEvents, 'can_edit_events': _canEditEvents};
}

class PatchCalendarRequest extends ApiRequestData {
  PatchCalendarRequest(this._title, this._canJoin, this._password);

  final String _title;
  final bool _canJoin;
  final String _password;

  Map<String, dynamic> toJson() {
    if (_password == null) {
      return {
        'title': _title,
        'can_join': _canJoin,
      };
    }

    return {
      'title': _title,
      'can_join': _canJoin,
      'password': _password,
    };
  }
}

class PatchCalendarLayoutRequest extends ApiRequestData {
  PatchCalendarLayoutRequest(Color color, IconData icon)
      : this._color = color.value,
        this._icon = icon.codePoint;

  final int _color;
  final int _icon;

  Map<String, dynamic> toJson() => {
        'color': _color,
        'icon': _icon,
      };
}

class CalendarInvitationTokenRequest extends ApiRequestData {
  CalendarInvitationTokenRequest(this._canCreateEvents, this._canEditEvents, this._expire);

  final bool _canCreateEvents;
  final bool _canEditEvents;

  final int _expire;

  Map<String, dynamic> toJson() => {
        'can_create_events': _canCreateEvents,
        'can_edit_events': _canEditEvents,
        'expire': _expire,
      };
}

class AcceptCalendarInvitationRequest extends ApiRequestData {
  AcceptCalendarInvitationRequest(this._invitationToken, Color color, IconData icon)
      : this._color = color.value,
        this._icon = icon.codePoint;

  final String _invitationToken;
  final int _color;
  final int _icon;

  Map<String, dynamic> toJson() => {
        'invitation_token': _invitationToken,
        'color': _color,
        'icon': _icon,
      };
}

class CreateEventRequest extends ApiRequestData {
  CreateEventRequest(this._beginDate, this._endDate, this._title, this._daylong, this._description, Color color) : this._color = color.value;

  final DateTime _beginDate;
  final DateTime _endDate;

  final String _title;
  final String _description;

  final bool _daylong;
  final int _color;

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
  PatchEventRequest(this._beginDate, this._endDate, this._title, this._daylong, this._description, Color color) : this._color = color.value;

  final DateTime _beginDate;
  final DateTime _endDate;

  final String _title;
  final String _description;

  final bool _daylong;
  final int _color;

  Map<String, dynamic> toJson() => {
        'begin_date': _beginDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'title': _title,
        'description': _description,
        'daylong': _daylong,
        'color': _color,
      };
}

class CreateVotingRequest extends ApiRequestData {
  CreateVotingRequest(this._title, this._multipleChoice, this._abstentionAllowed, this._choices);

  final String _title;

  final bool _multipleChoice;
  final bool _abstentionAllowed;

  final List<NewChoice> _choices;

  Map<String, dynamic> toJson() => {
        'title': _title,
        'multiple_choice': _multipleChoice,
        'abstention_allowed': _abstentionAllowed,
        'choices': _choices,
      };
}

class VoteRequest extends ApiRequestData {
  VoteRequest(this._choices);

  final List<int> _choices;

  Map<String, dynamic> toJson() => {
        'choice_ids': _choices,
      };
}

class CreateNoteRequest extends ApiRequestData {
  CreateNoteRequest(this._title, this._content, this._pinned, Color color) : this._color = color.value;

  final String _title;
  final String _content;

  final bool _pinned;
  final int _color;

  Map<String, dynamic> toJson() => {
        'title': _title,
        'content': _content,
        'pinned': _pinned,
        'color': _color,
      };
}

class PatchNoteRequest extends ApiRequestData {
  PatchNoteRequest(this._title, this._content, this._pinned, Color color) : this._color = color.value;

  final String _title;
  final String _content;

  final bool _pinned;
  final int _color;

  Map<String, dynamic> toJson() => {
        'title': _title,
        'content': _content,
        'pinned': _pinned,
        'color': _color,
      };
}
