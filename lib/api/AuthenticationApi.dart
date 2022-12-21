import 'dart:convert';

import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/SecureStorage.dart';

class AuthenticationApi extends ApiGateway {
  Future<ResponseCode> checkHashPassword(String password) async {
    String storedPassword = await SecureStorage.readVariable(SecureVariable.hashedPassword);

    if (storedPassword.isEmpty) {
      print("stored password not found!");
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

  Future<ApiResponse<String>> localLogin() async {
    try {
      String authToken = await SecureStorage.readVariable(SecureVariable.authToken);
      String refreshToken = await SecureStorage.readVariable(SecureVariable.refreshToken);

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
      print("local login: $error");
    }

    return ApiResponse(ResponseCode.unknown);
  }

  Future<ApiResponse<String>> remoteLogin(UserLoginRequest requestData) async {
    try {
      Response response = await sendRequest("/auth/login", RequestType.post, requestData);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (response.headers.containsKey("auth-token")) {
          await SecureStorage.writeVariable(SecureVariable.authToken, response.headers["auth-token"].toString());
        } else {
          print("Login-Error: No auth-token found");
        }

        if (response.headers.containsKey("refresh-token")) {
          await SecureStorage.writeVariable(SecureVariable.refreshToken, response.headers["refresh-token"].toString());
        } else {
          print("Login-Error: No refresh-token found");
        }

        var passwordBytes = utf8.encode(requestData.password);
        SecureStorage.writeVariable(SecureVariable.hashedPassword, sha256.convert(passwordBytes).toString());

        if (responseData.containsKey("user_id")) {
          return ApiResponse(ResponseCode.success, responseData["user_id"].toString());
        }
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
      print(error);
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
      print(error);
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
