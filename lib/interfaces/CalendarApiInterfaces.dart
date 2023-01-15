import 'dart:convert';

import 'package:flutter/material.dart';

import 'ApiInterfaces.dart';

class CreateCalendarRequest extends ApiRequestData {
  CreateCalendarRequest(this._title, this._password, this._canJoin, this._color, this._icon);

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
  JoinCalendarRequest(this._password, this._color, this._icon);

  final String _password;
  final int _color;
  final int _icon;

  @override
  Map<String, dynamic> toJson() => {'password': _password, 'color': _color, 'icon': _icon};
}

class PatchCalendarRequest extends ApiRequestData {
  PatchCalendarRequest(this.title, this.canJoin, this.colorLegend, this.password);

  final String title;
  final bool canJoin;
  final Map<int, String> colorLegend;

  final String? password;

  @override
  Map<String, dynamic> toJson() {
    if (password == null) {
      return {
        'title': title,
        'can_join': canJoin,
        'raw_color_legend': _convertColorLegendToJson(colorLegend),
      };
    }

    return {
      'title': title,
      'can_join': canJoin,
      'password': password,
    };
  }

  String _convertColorLegendToJson(Map<int, String> legend) {
    List<dynamic> colorList = [];

    legend.forEach((color, label) {
      colorList.add({
        'color': color,
        'label': label
      });
    });

    return jsonEncode({
      'legend': colorList
    });
  }
}

class PatchCalendarLayoutRequest extends ApiRequestData {
  PatchCalendarLayoutRequest(this._color, this._icon);

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
  AcceptCalendarInvitationRequest(this._invitationToken, this._color, this._icon);

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
  final int color;
  final int icon;
  final Map<int, String> colorLegend;

  LoadedCalendarData(this.id, this.fullName, this.canJoin, this.creationDate, this.color, this.icon, String rawColorLegend)
  : colorLegend = convertRawColorLegend(rawColorLegend);

  static Map<int, String> convertRawColorLegend(String json) {
    Map<int, String> colorLegend = {};

    try {
      Map<String, dynamic> rawData = jsonDecode(json);
      if (rawData.containsKey("legend")) {
        for (final colorLabel in rawData["legend"]) {
          final int color = colorLabel["color"];
          final String label = colorLabel["label"];

          colorLegend[color] = label;
        }
      }
    } catch (error) {
      debugPrint("Error when decoding color legend: $error");
      return {};
    }

    return colorLegend;
  }
}