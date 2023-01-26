import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' as material;
import 'package:http/http.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:xitem/api/ApiGateway.dart';
import 'package:xitem/controllers/StateController.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/User.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';
import 'package:xitem/utils/SecureStorage.dart';

class UserApi extends ApiGateway {
  Future<ApiResponse<AuthenticatedUser>> loadAppUserInformation(final String userID) async {
    Response response = await sendRequest("/user/$userID", RequestType.get, null, null, true);

    if (response.statusCode != 200) {
      return ApiResponse(extractResponseCode(response));
    }

    Map<String, dynamic> data = jsonDecode(response.body);

    String name = "ERROR", email = "ERROR", role = "ERROR", avatarHash = "";
    DateTime? birthday;
    DateTime registeredAt = DateTime.now();

    if (!data.containsKey("User")) {
      return ApiResponse(ResponseCode.userNotFound);
    }

    if (data["User"].containsKey("email")) {
      email = data["User"]["email"].toString();
    }

    if (data["User"].containsKey("name")) {
      name = data["User"]["name"].toString();
    }

    if (data["User"].containsKey("birthday")) {
      if (data["User"]["birthday"] != null) {
        birthday = DateTime.parse(data["User"]["birthday"].toString());
      }
    }

    if (data["User"].containsKey("profile_picture_hash")) {
      avatarHash = data["User"]["profile_picture_hash"].toString();
    }

    if (data["User"].containsKey("registered_at")) {
      registeredAt = DateTime.parse(data["User"]["registered_at"].toString());
    }

    if (data["User"].containsKey("roleObject")) {
      if (data["User"]["roleObject"].containsKey("role")) role = data["User"]["roleObject"]["role"].toString();
    }

    ApiResponse<File> loadedAvatar = await loadAvatar(userID, avatarHash);

    return ApiResponse(ResponseCode.success, AuthenticatedUser(User(userID, name, birthday, role, loadedAvatar.value), email, registeredAt));
  }

  Future<ApiResponse<User>> loadPublicUserInformation(final String userID) async {
    Response response = await sendRequest("/user/$userID", RequestType.get, null, null, true);

    if (response.statusCode != 200) {
      return ApiResponse(extractResponseCode(response));
    }

    Map<String, dynamic> data = jsonDecode(response.body);

    if (!data.containsKey("User")) {
      return ApiResponse(ResponseCode.userNotFound);
    }

    String name = "-", role = "-", avatarHash = "";
    DateTime? birthday;

    if (data["User"].containsKey("name")) name = data["User"]["name"].toString();

    if (data["User"].containsKey("birthday")) {
      if (data["User"]["birthday"] != null) {
        birthday = DateTime.parse(data["User"]["birthday"].toString());
      }
    }

    if (data["User"].containsKey("roleObject")) {
      if (data["User"]["roleObject"].containsKey("role")) {
        role = data["User"]["roleObject"]["role"].toString();
      }
    }

    if (data["User"].containsKey("profile_picture_hash")) {
      avatarHash = data["User"]["profile_picture_hash"].toString();
    }

    ApiResponse loadedAvatar = await loadAvatar(userID, avatarHash);
    return ApiResponse(ResponseCode.success, User(userID, name, birthday, role, loadedAvatar.value));
  }

  Future<ApiResponse<File>> loadAvatar(final String userID, final String avatarHash) async {

    final directory = await getApplicationDocumentsDirectory();
    File localAvatar = File('${directory.path}/$userID');

    if(await _getLocalAvatarHash(userID) != avatarHash || !localAvatar.existsSync()){
      material.debugPrint("Downloading Avatar for $userID...");

      if(localAvatar.existsSync()) {
        localAvatar.delete();
      }

      Response response = await sendRequest("/user/$userID/avatar", RequestType.get, null, null, true);

      if (response.statusCode != 200) {
        return ApiResponse(extractResponseCode(response));
      }

      localAvatar.writeAsBytesSync(response.bodyBytes);
      _addLocalAvatarHash(userID, avatarHash);
    } else {
      material.debugPrint("Using local Avatar for $userID...");
    }

    return ApiResponse(ResponseCode.success, localAvatar);
  }

  Future<ResponseCode> pushAvatarToServer(File avatarImage, final String userID) async {
    MultipartRequest request = MultipartRequest("PUT", Uri.parse("${ApiGateway.apiHost}/user/$userID/avatar"));

    request.files.add(MultipartFile.fromBytes("avatar", avatarImage.readAsBytesSync(), filename: path.basename(avatarImage.path)));

    String authToken = await StateController.authenticationController.getSecuredVariable(SecureVariable.authenticationToken);
    if (authToken.isEmpty) {
      return ResponseCode.unknown;
    }

    request.headers["auth-token"] = authToken;
    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return ResponseCode.success;
    } else if (response.statusCode == 413) {
      return ResponseCode.payloadTooLarge;
    } else if (response.statusCode == 400) {
      return ResponseCode.invalidFile;
    }

    return ResponseCode.unknown;
  }

  Future<ResponseCode> patchUser(final String userID, PatchUserRequest requestData) async {
    try {
      Response response = await sendRequest("/user/$userID", RequestType.patch, requestData, null, true);

      if (response.statusCode != 200) {
        return extractResponseCode(response);
      }

      return ResponseCode.success;
    } catch (error) {
      material.debugPrint(error.toString());
      return ResponseCode.unknown;
    }
  }

  Future<String?> _getLocalAvatarHash(final String userID) async {
    final Map<String, String> profilePictureHashMap = await _getLocalAvatarHashMap();
    return profilePictureHashMap[userID];
  }

  Future<void> _addLocalAvatarHash(final String userID, final String hash) async {
    File avatarHashStorage = await _getLocalAvatarHashMapFile();

    final Map<String, String> avatarHashMap = await _getLocalAvatarHashMap();
    avatarHashMap[userID] = hash;

    await avatarHashStorage.writeAsString(jsonEncode(avatarHashMap));
  }

  Future<Map<String, String>> _getLocalAvatarHashMap() async {
    Map<String, String> avatarHashMap = {};

    File avatarHashStorage = await _getLocalAvatarHashMapFile();

    try {
      final content = await avatarHashStorage.readAsString();
      Map<String, dynamic> data = jsonDecode(content);
      avatarHashMap = data.map((key, value) => MapEntry(key, value.toString()));
    } catch(e) {
      material.debugPrint(e.toString());
    }

    return avatarHashMap;
  }

  Future<File> _getLocalAvatarHashMapFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final localPath = directory.path;
    return File('$localPath/avatar_hashes.json');
  }
}
