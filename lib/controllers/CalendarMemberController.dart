import 'package:flutter/material.dart';
import 'package:xitem/api/CalendarMemberApi.dart';
import 'package:xitem/controllers/AuthenticationController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/CalendarMember.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class CalendarMemberController {
  CalendarMemberController(this._calendarMemberApi, this._authenticationController);

  final CalendarMemberApi _calendarMemberApi;
  final AuthenticationController _authenticationController;

  late final String _relatedCalendarID;
  late final String _authenticatedUserID;
  bool _isInitialized = false;

  late bool _authUserIsCalendarOwner;
  late bool _authUserCanCreateEvents;
  late bool _authUserCanEditEvents;

  List<CalendarMember> _memberList = <CalendarMember>[];

  List<CalendarMember> getMemberList() {
    if(!_isInitialized) {
      throw AssertionError("CalendarMemberController must be initialized before it can be accessed!");
    }

    return _memberList;
  }

  CalendarMember? getCalendarMember(String memberID) {
    if(!_isInitialized) {
      throw AssertionError("CalendarMemberController must be initialized before it can be accessed!");
    }

    for(CalendarMember member in _memberList) {
      if(member.userID == memberID) {
        return member;
      }
    }

    return null;
  }

  Future<ResponseCode> initialize(String relatedCalendarID, String authenticatedUserID) async {
    if(_isInitialized) {
      return ResponseCode.invalidAction;
    }

    _relatedCalendarID = relatedCalendarID;
    _authenticatedUserID = authenticatedUserID;

    ResponseCode initialLoad = await _loadAllMembers();

    if(initialLoad != ResponseCode.success) {
      _resetControllerState();
      return initialLoad;
    }

    _isInitialized = true;
    return ResponseCode.success;
  }

  Future<ResponseCode> _loadAllMembers() async {
    ApiResponse<List<CalendarMember>> loadAllMembers = await _calendarMemberApi.loadAllMembers(_relatedCalendarID);
    List<CalendarMember>? calendarMembers = loadAllMembers.value;

    if(loadAllMembers.code != ResponseCode.success) {
      return loadAllMembers.code;
    } else if(calendarMembers == null) {
      return ResponseCode.unknown;
    }

    _memberList = calendarMembers;

    _refreshAuthUserPermissions();
    _sortCalendarMemberList();

    debugPrint("${_memberList.length} Members loaded in Calendar: $_relatedCalendarID");

    return ResponseCode.success;
  }

  Future<ResponseCode> loadMember(String memberID) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarMemberController must be initialized before it can be accessed!");
    }

    ApiResponse<CalendarMember> loadMember = await _calendarMemberApi.loadSingleMember(_relatedCalendarID, memberID);
    CalendarMember? calendarMember = loadMember.value;

    if(loadMember.code != ResponseCode.success) {
      return loadMember.code;
    } else if(calendarMember == null) {
      return ResponseCode.unknown;
    }

    int memberIndex = -1;
    _memberList.asMap().forEach((index, member) {
      if (member.userID == memberID) {
        memberIndex = index;
      }
    });

    if (memberIndex >= 0 && memberIndex < _memberList.length) {
      _memberList[memberIndex] = calendarMember;
    } else {
      _memberList.add(calendarMember);
    }

    _refreshAuthUserPermissions();
    _sortCalendarMemberList();

    return ResponseCode.success;
  }

  Future<ResponseCode> changePermissions(String memberID, bool isOwner, bool canCreateEvents, bool canEditEvents) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarMemberController must be initialized before it can be accessed!");
    }

    ResponseCode patchMember = await _calendarMemberApi.patchMember(_relatedCalendarID, memberID, PatchCalendarMemberRequest(isOwner, canCreateEvents, canEditEvents));

    if(patchMember != ResponseCode.success) {
      return patchMember;
    }

    ResponseCode reload = await loadMember(memberID);
    if(reload != ResponseCode.success) {
      return reload;
    }

    _sortCalendarMemberList();

    return ResponseCode.success;
  }

  Future<ResponseCode> removeAssociatedUsers(String memberID, String userPassword) async {
    if(!_isInitialized) {
      throw AssertionError("CalendarMemberController must be initialized before it can be accessed!");
    }

    if(await _authenticationController.compareHashPassword(userPassword) != ResponseCode.success) {
      return ResponseCode.wrongPassword;
    }

    ResponseCode removeMember = await _calendarMemberApi.removeMember(_relatedCalendarID, memberID);
    if(removeMember != ResponseCode.success) {
      return removeMember;
    }

    int memberIndex = -1;
    _memberList.asMap().forEach((index, member) {
      if (member.userID == memberID) {
        memberIndex = index;
      }
    });

    if (memberIndex >= 0 && memberIndex < _memberList.length) {
      _memberList.removeAt(memberIndex);
    } else {
      return ResponseCode.memberNotFound;
    }

    _sortCalendarMemberList();

    return ResponseCode.success;
  }

  bool getAppUserCreatePermission() => _authUserCanCreateEvents;
  bool getAppUserEditPermission() => _authUserCanEditEvents;
  bool getAppUserOwnerPermission() => _authUserIsCalendarOwner;

  void _sortCalendarMemberList() {
    _memberList.sort((a, b) {
      if (a.userID == _authenticatedUserID) return 1;
      if (b.userID == _authenticatedUserID) return -1;

      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;
      if (a.isOwner && b.isOwner) return 0;

      if (a.canEditEvents && !b.canEditEvents) return -1;
      if (!a.canEditEvents && b.canEditEvents) return 1;
      if (a.canEditEvents && b.canEditEvents) return 0;

      if (a.canCreateEvents && !b.canCreateEvents) return -1;
      if (!a.canCreateEvents && b.canCreateEvents) return 1;

      return 0;
    });
  }

  void _refreshAuthUserPermissions() {
    int authUserIndex = _memberList.indexWhere((element) => _authenticatedUserID == element.userID);

    if(authUserIndex < 0) {
      _authUserCanCreateEvents = false;
      _authUserCanEditEvents = false;
      _authUserIsCalendarOwner = false;
    }

    _authUserCanCreateEvents = _memberList[authUserIndex].canCreateEvents;
    _authUserCanEditEvents = _memberList[authUserIndex].canEditEvents;
    _authUserIsCalendarOwner = _memberList[authUserIndex].isOwner;
  }

  void _resetControllerState() {
    _memberList.clear();
    _isInitialized = false;
  }
}