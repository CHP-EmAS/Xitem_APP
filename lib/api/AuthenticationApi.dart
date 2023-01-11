import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/SecureStorage.dart';

class AuthenticationApi extends ApiGateway {

  Future<ResponseCode> checkHashPassword(String password) async {
    String storedPassword = await StateController.getSecuredVariable(SecureVariable.hashedPassword);

    if (storedPassword.isEmpty) {
      debugPrint("Stored password not found!");
      return ResponseCode.unknown;
    }

    var passwordBytes = utf8.encode(password);
    String hash = sha256.convert(passwordBytes).toString();

    if (storedPassword == hash) {
      return ResponseCode.success;
    } else {
      return ResponseCode.wrongPassword;
    }
  }

  Future<ApiResponse<String>> requestUserIdByToken() async {
    try {
      String authToken = await StateController.getSecuredVariable(SecureVariable.authenticationToken);
      String refreshToken = await StateController.getSecuredVariable(SecureVariable.refreshToken);

      if (authToken.isEmpty || refreshToken.isEmpty) {
        return ApiResponse(ResponseCode.tokenRequired);
      }

      Response response = await sendRequest("/auth/id", RequestType.get, null, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey("user_id")) {
          return ApiResponse(ResponseCode.success, responseData["user_id"].toString());
        }
      }
    } catch (error) {
      debugPrint("local login: $error");
    }

    return ApiResponse(ResponseCode.unknown);
  }

  Future<ApiResponse<RemoteAuthenticationData>> remoteLogin(UserLoginRequest requestData) async {
    try {
      Response response = await sendRequest("/auth/login", RequestType.post, requestData);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String? authToken;
        String? refreshToken;
        String? userID;

        if (response.headers.containsKey("auth-token")) {
          authToken = response.headers["auth-token"];
        } else {
          debugPrint("Login-Error: No auth-token found");
        }

        if (response.headers.containsKey("refresh-token")) {
          refreshToken = response.headers["refresh-token"];
        } else {
          debugPrint("Login-Error: No refresh-token found");
        }

        if (responseData.containsKey("user_id")) {
          userID = responseData["user_id"];
        } else {
          debugPrint("Login-Error: No user ID found");
        }

        if(authToken == null || refreshToken == null || userID == null) {
          return ApiResponse(ResponseCode.authenticationFailed);
        }

        return ApiResponse(
            ResponseCode.success,
            RemoteAuthenticationData(
                authenticationToken: authToken,
                refreshToken: refreshToken,
                userID: userID
            )
        );
      }

      if (response.statusCode == 401) {
        return ApiResponse(ResponseCode.authenticationFailed);
      } else {
        return ApiResponse(extractResponseCode(response));
      }
    } catch (error) {
      return ApiResponse(ResponseCode.unknown);
    }
  }

  Future<ResponseCode> register(UserRegistrationRequest requestData) async {
    try {
      Response response = await sendRequest("/auth/send-verification", RequestType.post, requestData);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> changePassword(ChangePasswordRequest requestData) async {
    try {
      Response response = await sendRequest("/auth/change-password", RequestType.post, requestData, null, true);

      if (response.statusCode == 200) {
        return ResponseCode.success;
      }

      return extractResponseCode(response);
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<ResponseCode> sendPasswordEmail(String email) async {
    Response response = await sendRequest("/auth/reset_password/$email", RequestType.post);

    if (response.statusCode != 200) {
      return ResponseCode.unknown;
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> requestProfileInformationEmail(final String userID, String userPassword) async {
    ResponseCode checkPassword = await checkHashPassword(userPassword);

    if (checkPassword != ResponseCode.success) {
      return checkPassword;
    }

    Response response = await sendRequest("/user/$userID/infomail", RequestType.post, null, null, true, false);

    if (response.statusCode != 200) {
      return ResponseCode.unknown;
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> requestProfileDeletionEmail(final String userID, String userPassword) async {
    ResponseCode checkPassword = await checkHashPassword(userPassword);

    if (checkPassword != ResponseCode.success) {
      return checkPassword;
    }

    Response response = await sendRequest("/user/$userID/deletion_request", RequestType.post, null, null, true, true);

    if (response.statusCode != 200) {
      return ResponseCode.unknown;
    }

    return ResponseCode.success;
  }
}

class RemoteAuthenticationData {
  final String authenticationToken;
  final String refreshToken;
  final String userID;

  RemoteAuthenticationData({required this.authenticationToken, required this.refreshToken, required this.userID});
}
