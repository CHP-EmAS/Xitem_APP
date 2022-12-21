import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';
import 'package:path/path.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xitem/api/ApiGateway.dart';
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

    String name = "ERROR", email = "ERROR", role = "ERROR";
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

    if (data["User"].containsKey("registered_at")) {
      registeredAt = DateTime.parse(data["User"]["registered_at"].toString());
    }

    if (data["User"].containsKey("roleObject")) {
      if (data["User"]["roleObject"].containsKey("role")) role = data["User"]["roleObject"]["role"].toString();
    }

    ApiResponse loadedAvatar = await loadAvatar(userID);

    File? avatar;
    if (loadedAvatar.code != ResponseCode.success) {
      print("Avatar could not be loaded!");
    } else {
      avatar = loadedAvatar.value as File;
    }

    return ApiResponse(ResponseCode.success, AuthenticatedUser(User(userID, name, birthday, role, avatar), email, registeredAt));
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

    String name = "-", role = "-";
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

    ApiResponse loadedAvatar = await loadAvatar(userID);

    File? avatar;
    if (loadedAvatar.code != ResponseCode.success) {
      print("Avatar could not be loaded!");
    } else {
      avatar = loadedAvatar.value as File;
    }

    return ApiResponse(ResponseCode.success, User(userID, name, birthday, role, avatar));
  }

  Future<ApiResponse<File>> loadAvatar(final String userID) async {
    print("Downloading Avatar...");

    Response response = await get(Uri.parse("${ApiGateway.apiHost}/user/$userID/avatar"));

    if (response.statusCode != 200) {
      return ApiResponse(extractResponseCode(response));
    }

    final documentDirectory = await getApplicationDocumentsDirectory();

    File avatar = File(join(documentDirectory.path, '$userID.png'));

    avatar.writeAsBytesSync(response.bodyBytes);
    return ApiResponse(ResponseCode.success, avatar);
  }

  Future<ResponseCode> pushAvatarToServer(File avatarImage, final String userID) async {
    MultipartRequest request = MultipartRequest("PUT", Uri.parse("${ApiGateway.apiHost}/user/$userID/avatar"));

    Image? image = decodeImage(File(avatarImage.path).readAsBytesSync());
    if(image == null) {
      return ResponseCode.unknown;
    }

    avatarImage = File(avatarImage.path.replaceAll(basename(avatarImage.path), "out.png"))..writeAsBytesSync(encodePng(image));
    request.files.add(MultipartFile.fromBytes("avatar", avatarImage.readAsBytesSync(), filename: basename(avatarImage.path), contentType: MediaType("image", "png")));

    String authToken = await SecureStorage.readVariable(SecureVariable.authToken);
    if (authToken.isEmpty) {
      return ResponseCode.unknown;
    }

    request.headers["auth-token"] = authToken;
    StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return ResponseCode.success;
    } else if (response.statusCode == 413) {
      return ResponseCode.payloadTooLarge;
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
      print(error);
      return ResponseCode.unknown;
    }
  }
}
