import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:xitem/api/AuthenticationApi.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/SecureStorage.dart';

class AuthenticationController {
  static final SecureStorage _secureStorage = SecureStorage();
  final AuthenticationApi _authenticationApi;

  String _authenticatedUserID = "";
  bool _loggedIn = false;

  String get authenticatedUserID => _authenticatedUserID;
  bool get loggedIn => _loggedIn;

  AuthenticationController(this._authenticationApi);

  Future<ResponseCode> authenticateWithCredentials(String email, String password) async {
    if(_loggedIn) {
      return ResponseCode.invalidAction;
    }

    debugPrint("Authentication with credentials started...");

    ApiResponse<RemoteAuthenticationData> remoteLogin = await _authenticationApi.remoteLogin(UserLoginRequest(email, password));
    RemoteAuthenticationData? authData = remoteLogin.value;

    if(remoteLogin.code != ResponseCode.success) {
      debugPrint("Authentication with credentials failed with Code: ${remoteLogin.code}");
      return ResponseCode.authenticationFailed;
    } else if (authData == null) {
      debugPrint("Authentication with credentials failed because User ID is missing in response");
      return ResponseCode.internalError;
    }

    debugPrint("Authentication with credentials successful. Retrieved User ID: ${authData.userID}");
    debugPrint("Overwriting Secure Storage");

    _secureStorage.writeVariable(SecureVariable.authenticationToken, authData.authenticationToken);
    _secureStorage.writeVariable(SecureVariable.refreshToken, authData.refreshToken);

    List<int> passwordBytes = utf8.encode(password);
    _secureStorage.writeVariable(SecureVariable.hashedPassword, sha256.convert(passwordBytes).toString());

    _authenticatedUserID = authData.userID;
    _loggedIn = true;

    return ResponseCode.success;
  }

  Future<ResponseCode> authenticateWithSecuredToken() async {
    String authToken = await _secureStorage.readVariable(SecureVariable.authenticationToken);

    if(authToken.isEmpty) {
      return ResponseCode.authenticationFailed;
    }

    ApiResponse<String> userIdRequest = await _authenticationApi.requestUserIdByToken(authToken);

    String? userID = userIdRequest.value;
    if(userIdRequest.code != ResponseCode.success) {
      return userIdRequest.code;
    } else if(userID == null) {
      return ResponseCode.internalError;
    }

    _authenticatedUserID = userID;
    _loggedIn = true;

    return ResponseCode.success;
  }

  Future<ResponseCode> compareHashPassword(String password) async {
    String storedPassword = await _secureStorage.readVariable(SecureVariable.hashedPassword);

    if (storedPassword.isEmpty) {
      debugPrint("Stored password not found!");
      return ResponseCode.internalError;
    }

    var passwordBytes = utf8.encode(password);
    String hash = sha256.convert(passwordBytes).toString();

    if (storedPassword == hash) {
      return ResponseCode.success;
    } else {
      return ResponseCode.wrongPassword;
    }
  }

  Future<void> safeLogout() async {
    await _secureStorage.wipeStorage();

    _authenticatedUserID = "";
    _loggedIn = false;
  }

  Future<String> getSecuredVariable(SecureVariable variableKey) {
    return _secureStorage.readVariable(variableKey);
  }

  Future<bool> refreshAuthenticationToken() async {
    String oldAuthToken = await _secureStorage.readVariable(SecureVariable.authenticationToken);
    String refreshToken = await _secureStorage.readVariable(SecureVariable.refreshToken);

    String? authToken = await _authenticationApi.getRefreshedAuthenticationToken(oldAuthToken, refreshToken);

    if(authToken == null) {
     return false;
    }

    await _secureStorage.writeVariable(SecureVariable.authenticationToken, authToken);
    return true;
  }
}