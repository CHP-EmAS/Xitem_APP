import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';

class AuthenticationApi extends ApiGateway {

  Future<ApiResponse<String>> requestUserIdByToken(String authenticationToken) async {
    debugPrint("Requesting User ID by Authentication Token...");

    if (authenticationToken.isEmpty) {
      debugPrint("Login-Error: Authentication Token not found!");
      return ApiResponse(ResponseCode.tokenRequired);
    }

    try {
      Map<String, String> headers = {"Content-type": "application/json"};
      headers["auth-token"] = authenticationToken;

      Response response = await get(Uri.parse("${ApiGateway.apiHost}/auth/id"), headers: headers);

      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseData.containsKey("user_id")) {
          return ApiResponse(ResponseCode.success, responseData["user_id"].toString());
        }
      }

      return ApiResponse(extractResponseCode(response));
    } catch (error) {
      debugPrint("Login-Error: $error");
    }

    return ApiResponse(ResponseCode.internalError);
  }

  Future<String?> getRefreshedAuthenticationToken(String authenticationToken, String refreshToken) async {
    debugPrint("Refreshing Auth-Token..");

    if (authenticationToken.isEmpty || refreshToken.isEmpty) {
      debugPrint("Refresh-Error: authToken or refreshToken not found!");
      return null;
    }

    try {
      Map<String, String> headers = {"Content-type": "application/json"};
      headers["auth-token"] = authenticationToken;
      headers["refresh-token"] = refreshToken;

      Response response = await get(Uri.parse("${ApiGateway.apiHost}/auth/refresh"), headers: headers);

      if (response.statusCode == 200) {
        if (response.headers.containsKey("auth-token")) {
          return response.headers["auth-token"] as String;
        }
      }

      return null;
    } catch (error) {
      debugPrint("Error while refreshing Authentication Token: $error");
      return null;
    }
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
          debugPrint("Login-Error: No auth-token found in response");
        }

        if (response.headers.containsKey("refresh-token")) {
          refreshToken = response.headers["refresh-token"];
        } else {
          debugPrint("Login-Error: No refresh-token found in response");
        }

        if (responseData.containsKey("user_id")) {
          userID = responseData["user_id"];
        } else {
          debugPrint("Login-Error: No user ID found in response");
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
      debugPrint(error.toString());
      return ApiResponse(ResponseCode.internalError);
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
      return ResponseCode.internalError;
    }
  }

  Future<ResponseCode> changePassword(ChangePasswordRequest requestData) async {
    try {
      Response response = await sendRequest("/auth/change-password", RequestType.post, requestData, null, true);

      if (response.statusCode != 200) {
        return extractResponseCode(response);
      }

      return ResponseCode.success;
    } catch (error) {
      debugPrint(error.toString());
      return ResponseCode.internalError;
    }
  }

  Future<ResponseCode> sendPasswordEmail(String email) async {
    Response response = await sendRequest("/auth/reset_password/$email", RequestType.post);

    if (response.statusCode != 200) {
      return extractResponseCode(response);
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> requestProfileInformationEmail(final String userID, String userPassword) async {
    ResponseCode checkPassword = await StateController.authenticationController.compareHashPassword(userPassword);

    if (checkPassword != ResponseCode.success) {
      return checkPassword;
    }

    Response response = await sendRequest("/user/$userID/infomail", RequestType.post, null, null, true, false);

    if (response.statusCode != 200) {
      return extractResponseCode(response);
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> requestProfileDeletionEmail(final String userID, String userPassword) async {
    ResponseCode checkPassword = await StateController.authenticationController.compareHashPassword(userPassword);

    if (checkPassword != ResponseCode.success) {
      return checkPassword;
    }

    Response response = await sendRequest("/user/$userID/deletion_request", RequestType.post, null, null, true, true);

    if (response.statusCode != 200) {
      return extractResponseCode(response);
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
