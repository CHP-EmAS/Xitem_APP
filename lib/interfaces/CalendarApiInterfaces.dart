import 'dart:ui';

import 'package:flutter/material.dart';

import 'ApiInterfaces.dart';

class CreateCalendarRequest extends ApiRequestData {
  CreateCalendarRequest(this._title, this._password, this._canJoin, this._color, IconData icon)
      : _icon = icon.codePoint;

  final String _title;
  final String _password;

  final bool _canJoin;
  final int _color;

  final int _icon;

  @override
  Map<String, dynamic> toJson() => {
    'title': _title,
    'password': _password,
    'can_join': _canJoin,
    'color': _color,
    'icon': _icon,
  };
}

class JoinCalendarRequest extends ApiRequestData {
  JoinCalendarRequest(this._password, this._color, IconData icon)
       : _icon = icon.codePoint;

  final String _password;
  final int _color;
  final int _icon;

  @override
  Map<String, dynamic> toJson() => {'password': _password, 'color': _color, 'icon': _icon};
}

class PatchCalendarRequest extends ApiRequestData {
  PatchCalendarRequest(this._title, this._canJoin, this._password);

  final String _title;
  final bool _canJoin;
  final String? _password;

  @override
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
  PatchCalendarLayoutRequest(this._color, IconData icon)
      : _icon = icon.codePoint;

  final int _color;
  final int _icon;

  @override
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

  @override
  Map<String, dynamic> toJson() => {
    'can_create_events': _canCreateEvents,
    'can_edit_events': _canEditEvents,
    'expire': _expire,
  };
}

class AcceptCalendarInvitationRequest extends ApiRequestData {
  AcceptCalendarInvitationRequest(this._invitationToken, this._color, IconData icon)
      : this._icon = icon.codePoint;

  final String _invitationToken;
  final int _color;
  final int _icon;

  @override
  Map<String, dynamic> toJson() => {
    'invitation_token': _invitationToken,
    'color': _color,
    'icon': _icon,
  };
}

class LoadedCalendarData {
  final String id;
  final String fullName;
  final bool canJoin;
  final String creationDate;
  //final bool isOwner = calendar["is_owner"];
  //final bool canCreateEvents = calendar["can_create_events"];
  //final bool canEditEvents = calendar["can_edit_events"];
  final int color;
  final IconData icon;

  LoadedCalendarData(this.id, this.fullName, this.canJoin, this.creationDate, this.color, this.icon);
}