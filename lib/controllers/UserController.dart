import 'dart:io';

import 'package:xitem/api/UserApi.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class UserController {
  UserController(this._api);

  final UserApi _api;

  bool _isInitialized = false;

  late AuthenticatedUser _authenticatedUser;
  final Map<String, User> _userList = <String, User>{};

  Future<ResponseCode> initialize(String loggedInUserID) async {
    if(_isInitialized) {
      return ResponseCode.invalidAction;
    }

    ApiResponse<AuthenticatedUser> loadUser = await _api.loadAppUserInformation(loggedInUserID);

    if(loadUser.code != ResponseCode.success) {
      return loadUser.code;
    }

    _authenticatedUser = loadUser.value as AuthenticatedUser;
    _isInitialized = true;
    return ResponseCode.success;
  }

  AuthenticatedUser getAuthenticatedUser() {
    if(!_isInitialized) {
      throw AssertionError("UserController must be initialized before it can be accessed!");
    }

    return _authenticatedUser;
  }

  List<User> getUserList() {
    if(!_isInitialized) {
      throw AssertionError("UserController must be initialized before it can be accessed!");
    }

    return _userList.values.toList();
  }

  Future<ResponseCode> changeUserInformation(String name, DateTime? birthday) async {
    if(!_isInitialized) {
      throw AssertionError("UserController must be initialized before it can be accessed!");
    }

    ResponseCode patchUser = await _api.patchUser(_authenticatedUser.id, PatchUserRequest(name, birthday));

    if(patchUser == ResponseCode.success) {
      _authenticatedUser.name = name;
      _authenticatedUser.birthday = birthday;
    }

    return patchUser;
  }

  Future<ResponseCode> changeAvatar(File avatarImage) async {
    if(!_isInitialized) {
      throw AssertionError("UserController must be initialized before it can be accessed!");
    }

    ResponseCode pushAvatar = await _api.pushAvatarToServer(avatarImage, _authenticatedUser.id);

    if(pushAvatar == ResponseCode.success) {
      _authenticatedUser.avatar = avatarImage;
    }

    return pushAvatar;
  }

  Future<ApiResponse<User>> getUser(String userID) async {
    if(!_isInitialized) {
      throw AssertionError("UserController must be initialized before it can be accessed!");
    }

    if (userID == _authenticatedUser.id) {
      return ApiResponse(ResponseCode.success, _authenticatedUser);
    }

    if (!_userList.containsKey(userID)) {
      ResponseCode loadUser = await _loadUser(userID);

      if(loadUser != ResponseCode.success) {
        return ApiResponse(loadUser, null);
      }
    }

    return ApiResponse(ResponseCode.success, _userList[userID]);
  }

  User? getLoadedUser(String userID) {
    if (userID == _authenticatedUser.id) {
      return _authenticatedUser;
    }

    return _userList[userID];
  }

  Future<ResponseCode> _loadUser(String userID) async {
    if(!_isInitialized) {
      throw AssertionError("UserController must be initialized before it can be accessed!");
    }

    if (!_userList.containsKey(userID)) {
      ApiResponse<User> loadPublicUser = await _api.loadPublicUserInformation(userID);

      if(loadPublicUser.code == ResponseCode.success) {
        _userList[userID] = loadPublicUser.value!;
      }

      return loadPublicUser.code;
    }

    return ResponseCode.success;
  }
}
