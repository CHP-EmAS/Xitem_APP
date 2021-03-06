import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:de/Controllers/HolidayListController.dart';
import 'package:de/Controllers/SettingController.dart';
import 'package:de/Interfaces/api_interfaces.dart';
import 'package:de/Models/Calendar.dart';
import 'package:de/Models/Event.dart';
import 'package:de/Models/Member.dart';
import 'package:de/Models/Note.dart';
import 'package:de/Models/User.dart';
import 'package:de/Models/Voting.dart';
import 'package:de/Widgets/Dialogs/dialog_popups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as Image;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

import 'UserController.dart';

enum RequestType {
  POST,
  GET,
  PUT,
  PATCH,
  DELETE,
}

class Api {
  static final String appVersion = "1.1.16";
  static final String _apiHost = "https://api.xitem.de";

  static final _storage = new FlutterSecureStorage();

  static String errorCode = "";
  static String errorMessage = "";

  static bool _loggedIn = false;

  static String apiName = "Error";
  static String apiVersion = "0.0.0";

  //Password proof
  static Future<bool> checkHashPassword(String password) async {
    errorMessage = "Es ist ein unerwarteter Fehler aufgetreten! Bitte melde dich erneut an.";

    String storedPassword = await _storage.read(key: "hash_password");
    if (storedPassword == null) {
      print("stored password not found!");
      return false;
    }

    var passwordBytes = utf8.encode(password);
    String hash = sha256.convert(passwordBytes).toString();

    if (storedPassword == hash) {
      return true;
    } else {
      errorMessage = "Passwort falsch.";
    }

    return false;
  }

  //API
  static Future<bool> checkStatus() async {
    Response response = await _sendRequest("/", RequestType.GET);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("API_Name")) {
        apiName = data["API_Name"];
      }
      if (data.containsKey("Version")) {
        apiVersion = data["Version"];
      }

      print("Connected with: " + apiName + ", Version: " + apiVersion);

      return true;
    }

    return false;
  }

  //Auth Routes
  static Future<String> secureLogin() async {
    try {
      String authToken = await _storage.read(key: "auth-token");
      String refreshToken = await _storage.read(key: "refresh-token");

      if (authToken == null || refreshToken == null) return null;

      Response response = await _sendRequest("/auth/id", RequestType.GET, null, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey("user_id")) {
          _loggedIn = true;
          return responseData["user_id"].toString();
        }
      }

      return null;
    } catch (error) {
      errorMessage = "Es ist ein Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<String> login(UserLoginRequest requestData) async {
    try {
      Response response = await _sendRequest("/auth/login", RequestType.POST, requestData);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (response.headers.containsKey("auth-token"))
          await _storage.write(key: "auth-token", value: response.headers["auth-token"]);
        else
          print("Login-Error: No auth-token found");

        if (response.headers.containsKey("refresh-token"))
          await _storage.write(key: "refresh-token", value: response.headers["refresh-token"]);
        else
          print("Login-Error: No refresh-token found");

        var passwordBytes = utf8.encode(requestData.password);
        _storage.write(key: "hash_password", value: sha256.convert(passwordBytes).toString());

        if (responseData.containsKey("user_id")) {
          _loggedIn = true;
          return responseData["user_id"].toString();
        }
      }

      if (response.statusCode == 401) {
        errorMessage = "E-Mail oder Passwort falsch.";
      } else {
        switch (errorCode) {
          case "invalid_email":
            errorMessage = "Die angegebene E-Mail ist nicht gültig.";
            break;
          case "missing_argument":
            errorMessage = "Bitte geben sie alle Pflichtfelder an.";
            break;
          default:
            errorMessage = "Es ist ein Fehler aufgetreten, versuch es später erneut.";
            break;
        }
      }

      return null;
    } catch (error) {
      errorMessage = "Es ist ein Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<void> logout() async {
    _loggedIn = false;
    await _storage.deleteAll();
  }

  static Future<AppUser> loadAppUserInformation(final String userID) async {
    Response response = await _sendRequest("/user/$userID", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      String name, email, role;
      DateTime birthday, registeredAt;

      if (data["User"].containsKey("email")) email = data["User"]["email"].toString();

      if (data["User"].containsKey("name")) name = data["User"]["name"].toString();

      if (data["User"].containsKey("birthday")) {
        if (data["User"]["birthday"] != null)
          birthday = DateTime.parse(data["User"]["birthday"].toString());
        else
          birthday = null;
      }
      if (data["User"].containsKey("registered_at")) registeredAt = DateTime.parse(data["User"]["registered_at"].toString());

      if (data["User"].containsKey("roleObject")) {
        if (data["User"]["roleObject"].containsKey("role")) role = data["User"]["roleObject"]["role"].toString();
      }

      File loadedAvatar = await loadAvatar(userID);
      if (loadedAvatar == null) print("Avatar could not be loaded!");

      return new AppUser(userID, name, email, birthday, role, registeredAt, loadedAvatar);
    }

    return null;
  }

  static Future<PublicUser> loadPublicUserInformation(final String userID) async {
    Response response = await _sendRequest("/user/$userID", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      String name, role;
      DateTime birthday;

      if (data["User"].containsKey("name")) name = data["User"]["name"].toString();

      if (data["User"].containsKey("birthday")) {
        if (data["User"]["birthday"] != null)
          birthday = DateTime.parse(data["User"]["birthday"].toString());
        else
          birthday = null;
      }

      if (data["User"].containsKey("roleObject")) {
        if (data["User"]["roleObject"].containsKey("role")) role = data["User"]["roleObject"]["role"].toString();
      }

      File loadedAvatar = await loadAvatar(userID);
      if (loadedAvatar == null) print("Avatar could not be loaded!");

      return new PublicUser(userID, name, birthday, role, loadedAvatar);
    }

    return null;
  }

  static Future<bool> register(UserRegistrationRequest requestData) async {
    try {
      Response response = await _sendRequest("/auth/send-verification", RequestType.POST, requestData);

      if (response.statusCode == 200) {
        return true;
      }

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData.containsKey("Error")) {
        switch (responseData["Error"].toString()) {
          case "email_exists":
            errorMessage = "Ein Account mit dieser E-Mail existiert bereits";
            break;
          case "short_name":
            errorMessage = "Der Name muss mindestens 3 Zeichen lang sein.";
            break;
          case "invalid_email":
            errorMessage = "Die angegebene E-Mail ist nicht gültig.";
            break;
          case "invalid_date":
            errorMessage = "Der angegebene Geburtstag ist nicht gültig.";
            break;
          default:
            errorMessage = "Bei der Registrierung ist ein Fehler aufgetreten, versuch es später erneut.";
            break;
        }
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Bei der Registrierung ist ein Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  static Future<bool> changePassword(ChangePasswordRequest requestData) async {
    try {
      Response response = await _sendRequest("/auth/change-password", RequestType.POST, requestData, null, true);

      if (response.statusCode == 200) {
        return true;
      }

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData.containsKey("Error")) {
        switch (responseData["Error"].toString()) {
          case "missing_argument":
            errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
            break;
          case "short_password":
            errorMessage = "Dein Passwort muss mindestens 8 Zeichen lang sein.";
            break;
          case "repeat_wrong":
            errorMessage = "Die Passwörter stimmen nicht überien.";
            break;
          case "wrong_password":
            errorMessage = "Passwort falsch.";
            break;
          default:
            errorMessage = "Das Passwort konnte nicht geändert werden, versuch es später erneut.";
            break;
        }
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Das Passwort konnte nicht geändert werden, versuch es später erneut.";
      return false;
    }
  }

  static Future<bool> sendPasswordEmail(String email) async {
    Response response = await _sendRequest("/auth/reset_password/$email", RequestType.POST);

    if (response.statusCode == 200) return true;
    return false;
  }

  static Future<bool> requestProfileInformationEmail(final String userID, String userPassword) async {
    if (!await Api.checkHashPassword(userPassword)) return false;

    Response response = await _sendRequest("/user/$userID/infomail", RequestType.POST, null, null, true, false);

    if (response.statusCode == 200) return true;
    return false;
  }

  static Future<bool> requestProfileDeletionEmail(final String userID, String userPassword) async {
    if (!await Api.checkHashPassword(userPassword)) return false;

    Response response = await _sendRequest("/user/$userID/deletion_request", RequestType.POST, null, null, true, true);

    if (response.statusCode == 200) return true;
    return false;
  }

  //User Routes
  static Future<List<Calendar>> loadAssociatedCalendars(final String userID) async {
    List<Calendar> assocCalendars = new List<Calendar>();

    Response response = await _sendRequest("/user/$userID/calendars", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("associated_calendars")) {
        for (final calendar in data["associated_calendars"]) {
          final String id = calendar["calendarObject"]["calendar_id"];
          final String fullName = calendar["calendarObject"]["calendar_name"];
          final canJoin = calendar["calendarObject"]["can_join"];
          final String creationDate = calendar["calendarObject"]["creation_date"];
          final bool isOwner = calendar["is_owner"];
          final bool canCreateEvents = calendar["can_create_events"];
          final bool canEditEvents = calendar["can_edit_events"];
          final int color = int.parse(calendar["color"]);
          final int iconPoint = calendar["icon"];

          Calendar newCalendar = new Calendar(id, fullName, canJoin, creationDate, Color(color), IconData(iconPoint, fontFamily: 'MaterialIcons'), isOwner, canCreateEvents, canEditEvents);

          assocCalendars.add(newCalendar);
        }

        return assocCalendars;
      }
    }

    return null;
  }

  static Future<File> loadAvatar(final String userID) async {
    print("Downloading Avatar...");

    Response response = await get(_apiHost + "/user/$userID/avatar");

    if (response.statusCode == 200) {
      final documentDirectory = await getApplicationDocumentsDirectory();

      File avatar = new File(join(documentDirectory.path, userID + '.png'));

      avatar.writeAsBytesSync(response.bodyBytes);

      return avatar;
    }

    return null;
  }

  static Future<bool> pushAvatarToServer(File avatarImage, final String userID) async {
    var request = new MultipartRequest("PUT", Uri.parse(_apiHost + "/user/$userID/avatar"));

    var image = Image.decodeImage(new File(avatarImage.path).readAsBytesSync());

    avatarImage = new File(avatarImage.path.replaceAll(basename(avatarImage.path), "out.png"))..writeAsBytesSync(Image.encodePng(image));

    request.files.add(MultipartFile.fromBytes("avatar", avatarImage.readAsBytesSync(), filename: basename(avatarImage.path), contentType: MediaType("image", "png")));

    String authToken = await _storage.read(key: "auth-token");
    if (authToken == null) return false;

    request.headers["auth-token"] = authToken;

    var response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 413) {
      errorMessage = "Dein Profilbild überschreitet die maximale Dateigröße von 5MB.";
      return false;
    }

    switch (errorCode) {
      case "insufficient_permissions":
        errorMessage = "Du kannst dieses Profielbild nicht ändern.";
        break;
      case "user_not_found":
        errorMessage = "Nutzer nicht gefunden, versuche dich erneut anzumelden.";
        break;
      default:
        errorMessage = "Dein Profilbild konnten nicht gespeichert werden, versuch es später erneut.";
        break;
    }

    return false;
  }

  static Future<bool> patchUser(final String userID, PatchUserRequest requestData) async {
    try {
      Response response = await _sendRequest("/user/$userID", RequestType.PATCH, requestData, null, true);

      if (response.statusCode == 200) {
        return true;
      }

      switch (errorCode) {
        case "short_name":
          errorMessage = "Der Name muss mindestens 3 Zeichen lang sein.";
          break;
        case "invalid_date":
          errorMessage = "Der angegebene Geburtstag ist nicht gültig.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Die Änderungen konnten nicht gespeichert werden, versuch es später erneut.";
      return false;
    }
  }

  //Calendar Routes
  static Future<String> createCalendar(CreateCalendarRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar", RequestType.POST, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("calendar_id")) {
          return responseData["calendar_id"].toString();
        }
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case "invalid_title":
          errorMessage = "Unzulässiger Name. Zulässige Zeichen: a-z, A-Z, 0-9, Leerzeichen, _, -";
          break;
        case "short_password":
          errorMessage = "Das Passwort muss mindestens 6 Zeichen lang sein.";
          break;
        default:
          errorMessage = "Beim Erstellen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return null;
    } catch (error) {
      print(error);
      errorMessage = "Beim Erstellen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<String> joinCalendar(String hashName, JoinCalendarRequest requestData) async {
    hashName = hashName.replaceAll(new RegExp(r'#'), "%23");

    try {
      Response response = await _sendRequest("/calendar/" + hashName + "/user", RequestType.POST, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("calendar_id")) {
          return responseData["calendar_id"].toString();
        }
      } else if (response.statusCode == 401) {
        errorMessage = "Kalender-Name oder Passwort falsch.";
        return null;
      } else if (response.statusCode == 404) {
        errorMessage = "Kalender konnte nicht gefunden werden.";
        return null;
      } else if (response.statusCode == 403) {
        errorMessage = "Diesem Kalender kann nicht beigetreten werden.";
        return null;
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case "already_exists":
          errorMessage = "Du bist bereits Mitglied in diesem Kalender.";
          break;
        default:
          errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return null;
    } catch (error) {
      print(error);
      errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<bool> deleteCalendar(String calendarID) async {
    try {
      Response response = await _sendRequest("/calendar/" + calendarID, RequestType.DELETE, null, null, true, true);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        errorMessage = "Passwort falsch.";
        return false;
      } else if (response.statusCode == 403) {
        errorMessage = "Du kannst diesem Kalender nicht löschen.";
        return false;
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Es wurde kein Passwort angegeben.";
          break;
        default:
          errorMessage = "Beim Löschen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Beim Löschen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  static Future<bool> leaveCalendar(String calendarID) async {
    try {
      Response response = await _sendRequest("/calendar/" + calendarID + "/user/" + UserController.user.userID, RequestType.DELETE, null, null, true, true);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        errorMessage = "Passwort falsch.";
        return false;
      } else if (response.statusCode == 403) {
        errorMessage = "Du bist kein Mitglied in diesem Kalender. ";
        return false;
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Es wurde kein Passwort angegeben.";
          break;
        case "last_member":
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du das einzige Mitglied bist. Lösche den Kalender stattdessen.";
          break;
        case "last_owner":
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du der einzige Administrator bist. Ernenne einen anderen Administrator um den Kalender zu verlassen.";
          break;
        default:
          errorMessage = "Beim Verlassen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Beim Verlassen des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  static Future<Calendar> loadSingleCalendar(String calendarID) async {
    Response response = await _sendRequest("/calendar/$calendarID", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Calendar")) {
        Map<String, dynamic> calendar = data["Calendar"];

        final String id = calendar["calendarObject"]["calendar_id"];
        final String fullName = calendar["calendarObject"]["calendar_name"];
        final canJoin = calendar["calendarObject"]["can_join"];
        final String creationDate = calendar["calendarObject"]["creation_date"];
        final bool isOwner = calendar["is_owner"];
        final bool canCreateEvents = calendar["can_create_events"];
        final bool canEditEvents = calendar["can_edit_events"];
        final int color = int.parse(calendar["color"]);
        final int iconPoint = calendar["icon"];

        Calendar newCalendar = new Calendar(id, fullName, canJoin, creationDate, Color(color), IconData(iconPoint, fontFamily: 'MaterialIcons'), isOwner, canCreateEvents, canEditEvents);

        return newCalendar;
      }
    }

    return null;
  }

  static Future<List<AssociatedUser>> loadAssociatedUsers(String calendarID) async {
    List<AssociatedUser> assocUserList = new List<AssociatedUser>();

    Response response = await _sendRequest("/calendar/$calendarID/user", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("associated_users")) {
        for (final assocUser in data["associated_users"]) {
          print(assocUser.toString());
          final String userID = assocUser["user_id"];
          final bool isOwner = assocUser["is_owner"];
          final bool canCreateEvents = assocUser["can_create_events"];
          final bool canEditEvents = assocUser["can_edit_events"];

          AssociatedUser newAssocUser = new AssociatedUser(calendarID, userID, isOwner, canCreateEvents, canEditEvents);

          assocUserList.add(newAssocUser);
        }

        return assocUserList;
      } else {
        return null;
      }
    }

    return null;
  }

  static Future<AssociatedUser> loadAssociatedUser(String calendarID, String userID) async {
    Response response = await _sendRequest("/calendar/$calendarID/user/$userID", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("associated_user")) {
        dynamic assocUser = data["associated_user"];

        final String userID = assocUser["user_id"];
        final bool isOwner = assocUser["is_owner"];
        final bool canCreateEvents = assocUser["can_create_events"];
        final bool canEditEvents = assocUser["can_edit_events"];

        AssociatedUser newAssocUser = new AssociatedUser(calendarID, userID, isOwner, canCreateEvents, canEditEvents);

        return newAssocUser;
      } else {
        return null;
      }
    }

    return null;
  }

  static Future<bool> patchAssociatedUser(String calendarID, String userID, PatchAssociatedUserRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/user/$userID", RequestType.PATCH, requestData, null, true);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        errorMessage = "Du kannst diese Berechtigungen nicht ändern.";
        return false;
      } else if (response.statusCode == 404) {
        errorMessage = "Der ausgewählte Nutzer ist nicht Mitglied in diesem Kalender.";
        return false;
      }

      switch (errorCode) {
        case "last_owner":
          errorMessage = "Du kannst dir nicht die Administrationsrechte nehmen, da du der einzige Administrator bist. Ernenne zuerst einen anderen Administrator.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      return false;
    }
  }

  static Future<bool> removeAssociatedUser(String calendarID, String userID) async {
    try {
      Response response = await _sendRequest("/calendar/" + calendarID + "/user/" + userID, RequestType.DELETE, null, null, true, true);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        errorMessage = "Passwort falsch.";
        return false;
      } else if (response.statusCode == 403) {
        errorMessage = "Du bist kein Mitglied in diesem Kalender. ";
        return false;
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Es wurde kein Passwort angegeben.";
          break;
        case "last_member":
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du das einzige Mitglied bist. Lösche den Kalender stattdessen.";
          break;
        case "last_owner":
          errorMessage = "Du kannst diesen Kalender nicht verlassen da du der einzige Administrator bist. Ernenne einen anderen Administrator um den Kalender zu verlassen.";
          break;
        default:
          errorMessage = "Beim Entfernen des Nutzers ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Beim Entfernen des Nutzers ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  static Future<bool> patchCalendar(String calendarID, PatchCalendarRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID", RequestType.PATCH, requestData, null, true);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        errorMessage = "Du kannst diese Einstellungen nicht ändern.";
        return false;
      } else if (response.statusCode == 403) {
        errorMessage = "Du kannst diese Einstellungen nicht ändern.";
        return false;
      }

      switch (errorCode) {
        case "short_password":
          errorMessage = "Das Passwort muss mindestens 6 Zeichen lang sein.";
          break;
        case "invalid_title":
          errorMessage = "Unzulässiger Name. Zulässige Zeichen: a-z, A-Z, 0-9, Leerzeichen, _, -";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      return false;
    }
  }

  static Future<bool> patchCalendarLayout(String calendarID, PatchCalendarLayoutRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/layout", RequestType.PATCH, requestData, null, true);

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        errorMessage = "Du kannst diese Einstellungen nicht ändern.";
        return false;
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
      return false;
    }
  }

  static Future<String> getCalendarInvitationToken(String calendarID, CalendarInvitationTokenRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/invitation", RequestType.POST, requestData, null, true, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData.containsKey("Token")) {
          return responseData["Token"].toString();
        }
      }

      switch (errorCode) {
        case "insufficient_permissions":
          errorMessage = "Du musst Kalenderadministrator sein um eine QR-Code Einladung erstellen zu können.";
          break;
        case "access_forbidden":
          errorMessage = "Du musst Mitglied in diesem Kalender sein um eine QR-Code Einladung erstellen zu können.";
          break;
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case "invalid_number":
          errorMessage = "Die Gültigkeitsdauer muss zwischen 5min und 7Tagen liegen.";
          break;
        default:
          errorMessage = "Beim Erstellen der QR Einladung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return null;
    } catch (error) {
      print(error);
      errorMessage = "Beim Erstellen der QR Einladung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<String> acceptCalendarInvitationToken(AcceptCalendarInvitationRequest requestData) async {
    try {
      Response response = await _sendRequest("/invitation", RequestType.POST, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("calendar_id")) {
          return responseData["calendar_id"].toString();
        }
      }

      switch (errorCode) {
        case "invalid_token":
        case "expired_token":
          errorMessage = "Diese Einladung ist ungültig oder abgelaufen.";
          break;
        case "calendar_not_found":
          errorMessage = "Der Kalender den du betreten möchtest existiert nicht mehr.";
          break;
        case "calendar_not_joinable":
          errorMessage = "Diesem Kalender kann nicht beigetreten werden.";
          break;
        case "already_exists":
          errorMessage = "Du bist bereits Mitglied in diesem Kalender.";
          break;
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case "invalid_color":
          errorMessage = "Unzulässige Farbe.";
          break;
        default:
          errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return null;
    } catch (error) {
      print(error);
      errorMessage = "Beim Beitreten des Kalenders ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  //Event Routes
  static Future<List<Event>> loadEvents(String calendarID, DateTime beginPeriod, DateTime endPeriod) async {
    List<Event> eventList = new List<Event>();

    Response response =
        await _sendRequest("/filter/calendar/$calendarID/period?begin_date=${beginPeriod.toIso8601String()}&end_date=${endPeriod.toIso8601String()}", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Events")) {
        for (final event in data["Events"]) {
          final BigInt eventID = BigInt.parse(event["event_id"]);

          final String title = event["title"];
          final String description = event["description"];

          DateTime startDate = DateTime.parse(event["begin_date"]);
          DateTime endDate = DateTime.parse(event["end_date"]);

          final DateTime creationDate = DateTime.parse(event["creation_date"]);

          final int color = int.parse(event["color"]);

          final String createdByUser = event["created_by_user"];
          final bool daylong = event["daylong"];

          final tzConvertedStartDate = new tz.TZDateTime.from(startDate, SettingController.getTimeZone());
          startDate = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);

          final tzConvertedEndDate = new tz.TZDateTime.from(endDate, SettingController.getTimeZone());
          endDate = DateTime(tzConvertedEndDate.year, tzConvertedEndDate.month, tzConvertedEndDate.day, tzConvertedEndDate.hour, tzConvertedEndDate.minute);

          Event newEvent = new Event(eventID, startDate, endDate, title, description, Color(color), calendarID, createdByUser, daylong, creationDate);

          eventList.add(newEvent);
        }

        return eventList;
      }
    }

    return null;
  }

  static Future<Event> loadSingleEvent(String calendarID, BigInt eventID) async {
    Response response = await _sendRequest("/calendar/$calendarID/event/${eventID.toString()}", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Event")) {
        Map<String, dynamic> event = data["Event"];

        final BigInt eventID = BigInt.parse(event["event_id"]);
        final String title = event["title"];
        final String description = event["description"];

        DateTime startDate = DateTime.parse(event["begin_date"]);
        DateTime endDate = DateTime.parse(event["end_date"]);

        final DateTime creationDate = DateTime.parse(event["creation_date"]);
        final int color = int.parse(event["color"]);
        final String createdByUser = event["created_by_user"];
        final bool daylong = event["daylong"];

        final tzConvertedStartDate = new tz.TZDateTime.from(startDate, SettingController.getTimeZone());
        startDate = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);

        final tzConvertedEndDate = new tz.TZDateTime.from(endDate, SettingController.getTimeZone());
        endDate = DateTime(tzConvertedEndDate.year, tzConvertedEndDate.month, tzConvertedEndDate.day, tzConvertedEndDate.hour, tzConvertedEndDate.minute);

        Event newEvent = new Event(eventID, startDate, endDate, title, description, Color(color), calendarID, createdByUser, daylong, creationDate);

        return newEvent;
      }
    }

    return null;
  }

  static Future<BigInt> createEvent(String calendarID, CreateEventRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/event", RequestType.POST, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("event_id")) {
          return BigInt.parse(responseData["event_id"]);
        }
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case "invalid_title":
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        case "end_before_start":
          errorMessage = "Das Enddatum muss nach dem Startdatum liegen.";
          break;
        case "start_after_1900":
          errorMessage = "Das Startdatum muss nach dem 01.01.1900 liegen.";
          break;
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        case "invalid_color":
          errorMessage = "Unzulässige Farbe.";
          break;
        default:
          errorMessage = "Beim Erstellen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return null;
    } catch (error) {
      print(error);
      errorMessage = "Beim Erstellen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<bool> patchEvent(String calendarID, BigInt eventID, PatchEventRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/event/${eventID.toString()}", RequestType.PATCH, requestData, null, true);

      if (response.statusCode == 200) {
        return true;
      }

      switch (errorCode) {
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        case "event_not_found":
          errorMessage = "Event konnte nicht gefunden werden.";
          break;
        case "invalid_color":
          errorMessage = "Unzulässige Farbe.";
          break;
        case "invalid_title":
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        case "start_after_1900":
          errorMessage = "Das Startdatum muss nach dem 01.01.1900 liegen.";
          break;
        case "end_before_start":
          errorMessage = "Das Enddatum muss nach dem Startdatum liegen.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
          break;
      }
    } catch (error) {
      print(error);
      errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
    }

    return false;
  }

  static Future<bool> deleteEvent(String calendarID, BigInt eventID) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/event/${eventID.toString()}", RequestType.DELETE, null, null, true);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return true;
      }

      switch (errorCode) {
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Löschen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Beim Löschen des Events ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  //Voting Routes
  static Future<Voting> loadSingleVoting(String calendarID, int votingID) async {
    Response response = await _sendRequest("/calendar/$calendarID/voting/${votingID.toString()}", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Voting")) {
        Map<String, dynamic> voting = data["Voting"];

        final int votingID = voting["voting_id"];
        final String ownerID = voting["owner_id"];

        final String title = voting["title"];

        final bool multipleChoice = voting["multiple_choice"];
        final bool abstentionAllowed = voting["abstention_allowed"];

        final bool userHasVoted = voting["userHasVoted"];
        final int numberUsersWhoHaveVoted = voting["numberUsersWhoHaveVoted"];

        final DateTime creationDate = DateTime.parse(voting["creation_date"]);

        Map<int, Choice> choices = new Map<int, Choice>();

        for (final choice in voting["choices"]) {
          final int choiceID = choice["choice_id"];

          final String comment = choice["comment"];
          final int amountVotes = choice["amountVotes"];

          DateTime date;
          if (choice["date"] != null) {
            date = DateTime.parse(choice["date"]);

            final tzConvertedStartDate = new tz.TZDateTime.from(date, SettingController.getTimeZone());
            date = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);
          }

          choices[choiceID] = new Choice(choiceID, votingID, date, comment, amountVotes);
        }

        Voting newVoting = new Voting(votingID, calendarID, ownerID, title, multipleChoice, abstentionAllowed, userHasVoted, numberUsersWhoHaveVoted, choices, creationDate);

        return newVoting;
      }
    }

    return null;
  }

  static Future<List<Voting>> loadAllVoting(String calendarID) async {
    Response response = await _sendRequest("/calendar/$calendarID/voting", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      List<Voting> votingList = new List<Voting>();

      if (data.containsKey("Votings")) {
        for (final voting in data["Votings"]) {
          final int votingID = voting["voting_id"];
          final String ownerID = voting["owner_id"];

          final String title = voting["title"];

          final bool multipleChoice = voting["multiple_choice"];
          final bool abstentionAllowed = voting["abstention_allowed"];

          final bool userHasVoted = voting["userHasVoted"];
          final int numberUsersWhoHaveVoted = voting["numberUsersWhoHaveVoted"];

          final DateTime creationDate = DateTime.parse(voting["creation_date"]);

          Map<int, Choice> choices = new Map<int, Choice>();

          for (final choice in voting["choices"]) {
            final int choiceID = choice["choice_id"];

            final String comment = choice["comment"];
            final int amountVotes = choice["amountVotes"];

            DateTime date;
            if (choice["date"] != null) {
              date = DateTime.parse(choice["date"]);

              final tzConvertedStartDate = new tz.TZDateTime.from(date, SettingController.getTimeZone());
              date = DateTime(tzConvertedStartDate.year, tzConvertedStartDate.month, tzConvertedStartDate.day, tzConvertedStartDate.hour, tzConvertedStartDate.minute);
            }

            choices[choiceID] = new Choice(choiceID, votingID, date, comment, amountVotes);
          }

          Voting newVoting = new Voting(votingID, calendarID, ownerID, title, multipleChoice, abstentionAllowed, userHasVoted, numberUsersWhoHaveVoted, choices, creationDate);

          votingList.add(newVoting);
        }

        return votingList;
      }
    }

    return null;
  }

  static Future<int> createVoting(String calendarID, CreateVotingRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/voting", RequestType.POST, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("voting_id")) {
          return responseData["voting_id"];
        }
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case "invalid_title":
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        case "start_after_1900":
          errorMessage = "Das Ablaufdatum muss nach dem 01.01.1900 liegen.";
          break;
        case "invalid_choice_amount":
          errorMessage = "Es müssen mindestens 2 Abstimmungsmöglichkeiten hinzugefügt werden.";
          break;
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um eine Abstimmung in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Erstellen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return null;
    } catch (error) {
      print(error);
      errorMessage = "Beim Erstellen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<bool> deleteVoting(String calendarID, int votingID) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/voting/${votingID.toString()}", RequestType.DELETE, null, null, true);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return true;
      }

      switch (errorCode) {
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um eine Abstimmung in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Löschen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Beim Löschen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  static Future<bool> vote(String calendarID, int votingID, VoteRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/voting/$votingID/vote", RequestType.POST, requestData, null, true);

      if (response.statusCode == 201) {
        return true;
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Bei der Abstimmung wurde kein ausgewählter Termin oder eine Enthaltung übermittelt.";
          break;
        case "already_voted":
          errorMessage = "Du hast bereits an der Abstimmung teilgenommen.";
          break;
        case "no_multiple_choice_enabled":
          errorMessage = "Eine Mehrfachauswahl ist bei dieser Abstimmung nicht möglich.";
          break;
        case "voting_not_found":
          errorMessage = "Die angefragte Abstimmung konnte nicht gefunden werden.";
          break;
        case "choice_not_found":
          errorMessage = "Mindestens einer der asugewählten Termine konnte nicht gefunden werden oder ist nicht Teil der Abstimmung.";
          break;
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um an der Abstimmung in diesem Kalender teilzunehmen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Erstellen der Abstimmung ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Beim Abstimmen ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  //Note Routes
  static Future<List<Note>> loadAllNotes(String calendarID) async {
    List<Note> noteList = new List<Note>();

    Response response = await _sendRequest("/calendar/$calendarID/note", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Notes")) {
        for (final note in data["Notes"]) {
          final BigInt noteID = BigInt.parse(note["note_id"]);

          final String title = note["title"];
          final String content = note["content"];

          final int color = int.parse(note["color"]);
          final bool pinned = note["pinned"];

          final String ownerID = note["owner_id"];

          final DateTime creationDate = DateTime.parse(note["creation_date"]);
          final DateTime modificationDate = DateTime.parse(note["modification_date"]);

          Note loadedNote = new Note(noteID, title, content, Color(color), pinned, calendarID, ownerID, creationDate, modificationDate);

          noteList.add(loadedNote);
        }

        return noteList;
      }
    }

    return null;
  }

  static Future<Note> loadSingleNote(String calendarID, BigInt noteID) async {
    Response response = await _sendRequest("/calendar/$calendarID/note/${noteID.toString()}", RequestType.GET, null, null, true);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Note")) {
        Map<String, dynamic> note = data["Event"];

        final BigInt noteID = BigInt.parse(note["note_id"]);
        final String title = note["title"];
        final String content = note["content"];

        final String ownerID = note["owner_id"];

        final int color = int.parse(note["color"]);
        final bool pinned = note["pinned"];

        final DateTime creationDate = DateTime.parse(note["creation_date"]);
        final DateTime modificationDate = DateTime.parse(note["modification_date"]);

        Note loadedNote = new Note(noteID, title, content, Color(color), pinned, calendarID, ownerID, creationDate, modificationDate);

        return loadedNote;
      }
    }

    return null;
  }

  static Future<BigInt> createNote(String calendarID, CreateNoteRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/note", RequestType.POST, requestData, null, true);

      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData.containsKey("note_id")) {
          return BigInt.parse(responseData["note_id"]);
        }
      }

      switch (errorCode) {
        case "missing_argument":
          errorMessage = "Bitte füllen Sie alle Pflichtfelder aus.";
          break;
        case "invalid_title":
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Erstellen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return null;
    } catch (error) {
      print(error);
      errorMessage = "Beim Erstellen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return null;
    }
  }

  static Future<bool> patchNote(String calendarID, BigInt noteID, PatchNoteRequest requestData) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/note/${noteID.toString()}", RequestType.PATCH, requestData, null, true);

      if (response.statusCode == 200) {
        return true;
      }

      switch (errorCode) {
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um ein Event in diesem Kalender zu erstellen. Bitte wende dich an den Kalenderadministrator";
          break;
        case "note_not_found":
          errorMessage = "Notiz konnte nicht gefunden werden.";
          break;
        case "invalid_title":
          errorMessage = "Unzulässiger Titel. Titel muss mindestens 3 Zeichen lang sein.";
          break;
        default:
          errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
          break;
      }
    } catch (error) {
      print(error);
      errorMessage = "Die Änderungen konnten nicht gespeichert werden werden, versuch es später erneut.";
    }

    return false;
  }

  static Future<bool> deleteNote(String calendarID, BigInt noteID) async {
    try {
      Response response = await _sendRequest("/calendar/$calendarID/note/${noteID.toString()}", RequestType.DELETE, null, null, true);

      if (response.statusCode == 200 || response.statusCode == 404) {
        return true;
      }

      switch (errorCode) {
        case "access_forbidden":
        case "insufficient_permissions":
          errorMessage = "Du hast nicht die nötigen Berechtigungen um eine Notiz in diesem Kalender zu löschen. Bitte wende dich an den Kalenderadministrator";
          break;
        default:
          errorMessage = "Beim Löschen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
          break;
      }

      return false;
    } catch (error) {
      print(error);
      errorMessage = "Beim Löschen der Notiz ist ein unerwarteter Fehler aufgetreten, versuch es später erneut.";
      return false;
    }
  }

  //Holiday Routes
  static Future<List<PublicHoliday>> loadHolidays(int year, StateCode stateCode) async {
    Response response = await _sendRequest("/holidays/$year/${HolidayController.getStateCode(stateCode)}", RequestType.GET);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("Holidays")) {
        List<PublicHoliday> publicHolidays = new List<PublicHoliday>();

        for (final publicHoliday in data["Holidays"]) {
          final String name = publicHoliday["name"].toString();
          final DateTime date = DateTime.parse(publicHoliday["date"]);

          PublicHoliday newPublicHoliday = new PublicHoliday(name, date);
          publicHolidays.add(newPublicHoliday);
        }

        return publicHolidays;
      }
    }

    return null;
  }

  //Token
  static Future<bool> refreshToken() async {
    print("Refreshing Auth-Token..");

    String authToken = await _storage.read(key: "auth-token");
    String refreshToken = await _storage.read(key: "refresh-token");

    if (authToken == null || refreshToken == null) {
      print("Refresh-Error: authToken or refreshToken not found!");
      return false;
    }

    try {
      Map<String, String> headers = {"Content-type": "application/json"};
      headers["auth-token"] = authToken;
      headers["refresh-token"] = refreshToken;
      Response response = await get(_apiHost + "/auth/refresh", headers: headers);

      if (response.statusCode == 200) {
        if (response.headers.containsKey("auth-token")) {
          await _storage.write(key: "auth-token", value: response.headers["auth-token"]);
          print("Auth-Token refreshed!");
          return true;
        }
      }

      return false;
    } catch (error) {
      return false;
    }
  }

  static Future<String> getSecurityToken() async {
    print("Requesting Security-Token..");
    String refreshToken = await _storage.read(key: "refresh-token");

    if (refreshToken == null) {
      print("Request-Security-Error: authToken or refreshToken not found!");
      return null;
    }

    try {
      Response response = await _sendRequest("/auth/security", RequestType.GET, null, {"refresh-token": refreshToken}, true, false);

      if (response.statusCode == 200) {
        if (response.headers.containsKey("security-token")) {
          print("Security-Token received!");
          return response.headers["security-token"];
        }
      }

      return null;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  //Http functions
  static Future<Response> _sendRequest(String relativeURL, RequestType type,
      [ApiRequestData requestData, Map<String, String> optionalHeaders, bool includeAuthToken = false, bool includeSecurityToken = false]) async {
    print("[" + type.toString() + "] > " + relativeURL);

    String jsonRequestData = "";

    if (requestData != null) {
      jsonRequestData = jsonEncode(requestData.toJson());
    }

    Map<String, String> headers = {"Content-type": "application/json"};

    if (includeAuthToken) {
      String authToken = await _storage.read(key: "auth-token");
      headers["auth-token"] = authToken;
    }

    if (includeSecurityToken) {
      String securityToken = await getSecurityToken();
      headers["security-token"] = securityToken;
    }

    if (optionalHeaders != null) headers.addAll(optionalHeaders);

    Response response;
    switch (type) {
      case RequestType.GET:
        response = await get(_apiHost + relativeURL, headers: headers);
        break;
      case RequestType.POST:
        response = await post(_apiHost + relativeURL, headers: headers, body: jsonRequestData);
        break;
      case RequestType.PATCH:
        response = await patch(_apiHost + relativeURL, headers: headers, body: jsonRequestData);
        break;
      case RequestType.PUT:
        response = await put(_apiHost + relativeURL, headers: headers, body: jsonRequestData);
        break;
      case RequestType.DELETE:
        response = await delete(_apiHost + relativeURL, headers: headers);
        break;
    }

    if (response.statusCode >= 400 && response.statusCode <= 600) {
      Map<String, dynamic> responseData;

      try {
        responseData = jsonDecode(response.body);
      } catch (error) {
        print("Error while decode response message!\n" + error.toString());
        errorCode = "unexpected_response";
        return response;
      }

      print(response.body.toString());

      if (responseData.containsKey("Error")) {
        errorCode = responseData["Error"] as String;
      } else {
        errorCode = "";
      }

      if (errorCode == "expired_token") {
        bool refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          return _sendRequest(relativeURL, type, requestData, optionalHeaders, includeAuthToken);
        } else {
          if (_loggedIn) {
            await UserController.logout();
          }
        }
      } else {
        bool logout = false;

        switch (errorCode) {
          case "token_required":
            print("Error: Token required! Request: " + relativeURL);
            break;
          case "banned":
            await DialogPopup.asyncOkDialog("Authentifizierungsfehler", "Dein Account konnte nicht verifiziert werden.\nUrsache: Account gebannt.");
            logout = true;
            break;
          case "pass_changed":
            await DialogPopup.asyncOkDialog("Authentifizierungsfehler", "Dein Account konnte nicht verifiziert werden.\nUrsache: Passwort wurde geändert.");
            logout = true;
            break;
          case "invalid_token":
            await DialogPopup.asyncOkDialog("Authentifizierungsfehler", "Dein Account konnte nicht verifiziert werden.\nUrsache: Verifizierung ist fehlerhaft.");
            logout = true;
            break;
        }

        if (logout && _loggedIn) {
          await UserController.logout();
        }
      }
    } else {
      errorCode = "";
    }

    return response;
  }
}
