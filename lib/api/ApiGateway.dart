import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/SecureStorage.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';

enum RequestType {
  post,
  get,
  put,
  patch,
  delete,
}

class ApiGateway {
  static const String apiHost = "https://api.xitem.de";

  static const int _maximumRetries = 5;
  int _retryCounter = 0;

  Future<ApiResponse<String>> checkStatus() async {
    Response response = await sendRequest("/", RequestType.get);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      String apiInfo= "";

      if (data.containsKey("API_NAME")) {
        apiInfo = data["API_NAME"];
      }

      if (data.containsKey("API_VERSION")) {
        apiInfo += " ${data["API_VERSION"]}";
      }

      debugPrint("Connected with: $apiInfo");

      return ApiResponse(ResponseCode.success, apiInfo);
    }

    return ApiResponse(extractResponseCode(response));
  }

  ResponseCode extractResponseCode(Response response) {
    Map<String, dynamic> responseData;

    //decode response form JSON to Object
    try {
      responseData = jsonDecode(response.body);
    } catch (error) {
      debugPrint("Error while decode response message!\n$error");
      return ResponseCode.unknown;
    }

    if (responseData.containsKey("Error")) {
      return ApiResponseMapper.map(responseData["Error"] as String);
    }

    return ResponseCode.unknown;
  }

  Future<Response> sendRequest(String relativeURL, RequestType type,
      [ApiRequestData? requestData, Map<String, String>? optionalHeaders, bool includeAuthToken = false, bool includeSecurityToken = false]) async {
    //log request
    debugPrint("[$type] > $relativeURL");

    String body = requestData != null ? jsonEncode(requestData.toJson()) : "";
    Map<String, String> headers = await _buildHeader(includeAuthToken, includeSecurityToken, optionalHeaders);

    //execute request
    Response response;
    switch (type) {
      case RequestType.get:
        response = await get(Uri.parse(apiHost + relativeURL), headers: headers);
        break;
      case RequestType.post:
        response = await post(Uri.parse(apiHost + relativeURL), headers: headers, body: body);
        break;
      case RequestType.patch:
        response = await patch(Uri.parse(apiHost + relativeURL), headers: headers, body: body);
        break;
      case RequestType.put:
        response = await put(Uri.parse(apiHost + relativeURL), headers: headers, body: body);
        break;
      case RequestType.delete:
        response = await delete(Uri.parse(apiHost + relativeURL), headers: headers);
        break;
    }

    //On Error
    if (response.statusCode >= 400 && response.statusCode <= 600) {
      //computes only authentication errors -> true: need to refresh token
      if (await _computeAuthError(response)) {
        if (_retryCounter >= _maximumRetries) {
          await StandardDialog.okDialog(
              "Laufzeitfehler", "Anfragen an den Server waren nach mehrmaligen Versuchen nicht erfolgreich. Bitte versuche es später erneut oder kontaktiere den Administrator");

          _retryCounter = 0;
          StateController.safeLogout();
        } else {
          if (_retryCounter > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }

          _retryCounter++;
          bool refreshSuccess = await _refreshToken();

          if (!refreshSuccess) {
            await StandardDialog.okDialog("Authentifizierungsfehler", "Dein Account konnte nicht verifiziert werden.\nUrsache: Verifizierung ist fehlerhaft.");
            _retryCounter = 0;
            StateController.safeLogout();
          } else {
            //recursive request
            Response retriedResponse = await sendRequest(relativeURL, type, requestData, optionalHeaders, includeAuthToken);
            _retryCounter = 0;
            return retriedResponse;
          }
        }
      }
    }

    //return response for further processing
    return response;
  }

  Future<Map<String, String>> _buildHeader(bool includeAuthToken, bool includeSecurityToken, Map<String, String>? optionalHeaders) async {
    Map<String, String> headers = {"Content-type": "application/json"};

    //include auth token if requested
    if (includeAuthToken) {
      headers["auth-token"] = await StateController.getSecuredVariable(SecureVariable.authenticationToken);
    }

    //include security token if requested, this token must be requested in advance
    if (includeSecurityToken) {
      headers["security-token"] = await _getSecurityToken();
    }

    if (optionalHeaders != null) {
      headers.addAll(optionalHeaders);
    }

    return headers;
  }

  Future<bool> _computeAuthError(Response response) async {
    ResponseCode errorCode = extractResponseCode(response);

    //If the Auth token has expired, an attempt is made to renew it.
    // If the renewal was successful, the request is recursively executed again,
    // if not, the user is logged out because it can no longer be authenticated.
    if (errorCode == ResponseCode.tokenExpired) {
      return true;
    } else if (errorCode == ResponseCode.tokenRequired) {
      debugPrint("Error: Token required! Request: ${response.request?.url}");
    } else {
      //If the user can no longer be authenticated,
      //he is logged out with an appropriate error message.
      switch (errorCode) {
        case ResponseCode.userBanned:
          await StandardDialog.okDialog("Authentifizierungsfehler", "Dein Account konnte nicht verifiziert werden.\nUrsache: Account gebannt.");
          StateController.safeLogout();
          break;
        case ResponseCode.passwordChanged:
          await StandardDialog.okDialog("Authentifizierungsfehler", "Dein Account konnte nicht verifiziert werden.\nUrsache: Passwort wurde geändert.");
          StateController.safeLogout();
          break;
        case ResponseCode.tokenRequired:
          await StandardDialog.okDialog("Authentifizierungsfehler", "Dein Account konnte nicht verifiziert werden.\nUrsache: Verifizierung ist fehlerhaft.");
          StateController.safeLogout();
          break;
        default:
          //No errors that interest us at this level
          return false;
      }
    }

    return false;
  }

  Future<bool> _refreshToken() async {
    debugPrint("Refreshing Auth-Token..");

    String authToken = await StateController.getSecuredVariable(SecureVariable.authenticationToken);
    String refreshToken = await StateController.getSecuredVariable(SecureVariable.refreshToken);

    if (authToken.isEmpty || refreshToken.isEmpty) {
      debugPrint("Refresh-Error: authToken or refreshToken not found!");
      return false;
    }

    try {
      Map<String, String> headers = {"Content-type": "application/json"};
      headers["auth-token"] = authToken;
      headers["refresh-token"] = refreshToken;
      Response response = await get(Uri.parse("$apiHost/auth/refresh"), headers: headers);

      if (response.statusCode == 200) {
        if (response.headers.containsKey("auth-token")) {
          await StateController.setAuthToken(response.headers["auth-token"] as String);
          debugPrint("Auth-Token refreshed!");
          return true;
        }
      }

      return false;
    } catch (error) {
      return false;
    }
  }

  Future<String> _getSecurityToken() async {
    debugPrint("Requesting Security-Token..");

    String authToken = await StateController.getSecuredVariable(SecureVariable.authenticationToken);
    String refreshToken = await StateController.getSecuredVariable(SecureVariable.refreshToken);

    if (authToken.isEmpty || refreshToken.isEmpty) {
      debugPrint("Request-Security-Error: authToken or refreshToken not found!");
      return "";
    }

    try {
      Map<String, String> headers = {"Content-type": "application/json"};
      headers["auth-token"] = authToken;
      headers["refresh-token"] = refreshToken;

      Response response = await get(Uri.parse("$apiHost/auth/security"), headers: headers);


      if (response.statusCode == 200) {
        if (response.headers.containsKey("security-token")) {
          debugPrint("Security-Token received!");
          return response.headers["security-token"] as String;
        }
      }

      return "";
    } catch (error) {
      debugPrint("Security token cannot be requested:\n$error");
      return "";
    }
  }

}
