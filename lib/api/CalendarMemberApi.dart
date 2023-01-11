import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/CalendarMember.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class CalendarMemberApi extends ApiGateway{

  Future<ApiResponse<List<CalendarMember>>> loadAllMembers(String calendarID) async {
    List<CalendarMember> memberList = <CalendarMember>[];

    Response response = await sendRequest("/calendar/$calendarID/user", RequestType.get, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("associated_users")) {
        for (final member in data["associated_users"]) {

          final String userID = member["user_id"];
          final bool isOwner = member["is_owner"];
          final bool canCreateEvents = member["can_create_events"];
          final bool canEditEvents = member["can_edit_events"];

          CalendarMember newMember = CalendarMember(calendarID, userID, isOwner, canCreateEvents, canEditEvents);

          memberList.add(newMember);
        }

        return ApiResponse(ResponseCode.success, memberList);
      }
    }

    return ApiResponse(extractResponseCode(response));
  }

  Future<ApiResponse<CalendarMember>> loadSingleMember(String calendarID, String userID) async {
    Response response = await sendRequest("/calendar/$calendarID/user/$userID", RequestType.get, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("associated_user")) {
        dynamic assocUser = data["associated_user"];

        final String userID = assocUser["user_id"];
        final bool isOwner = assocUser["is_owner"];
        final bool canCreateEvents = assocUser["can_create_events"];
        final bool canEditEvents = assocUser["can_edit_events"];

        CalendarMember newMember = CalendarMember(calendarID, userID, isOwner, canCreateEvents, canEditEvents);

        return ApiResponse(ResponseCode.success, newMember);
      }
    }

    return ApiResponse(extractResponseCode(response));
  }

  Future<ResponseCode> patchMember(String calendarID, String userID, PatchCalendarMemberRequest requestData) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/user/$userID", RequestType.patch, requestData, null, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> removeMember(String calendarID, String userID) async {
    try {
      Response response = await sendRequest("/calendar/$calendarID/user/$userID", RequestType.delete, null, null, true, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }
}