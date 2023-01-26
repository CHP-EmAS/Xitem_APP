class ApiResponse<T> {
  ApiResponse(this.code,[this.value]);

  ApiResponse.fromStrCode(String strCode, this.value)
      : code = ApiResponseMapper.map(strCode);

  final T? value;
  final ResponseCode code;
}

class ApiResponseMapper {
  static ResponseCode map(String strCode) {
    switch (strCode) {
      case "success":
        return ResponseCode.success;
      //-------- Calendar --------//
      case "already_exists":
        return ResponseCode.assocUserAlreadyExists;
      case "not_empty":
        return ResponseCode.calendarNotEmpty;
      case "last_member":
        return ResponseCode.lastMember;
      case "last_owner":
        return ResponseCode.lastOwner;
      //-------- Event --------//
      case "end_before_start":
        return ResponseCode.endBeforeStart;
      case "start_after_1900":
        return ResponseCode.startAfter1900;
      //-------- Voting --------//
      case "already_voted":
        return ResponseCode.alreadyVoted;
      case "no_multiple_choice_enabled":
        return ResponseCode.noMultipleChoiceEnabled;
      case "invalid_choice_amount":
        return ResponseCode.invalidChoiceAmount;
      //-------- 400 --------//
      case "email_exists":
        return ResponseCode.emailExistsError;
      case "missing_argument":
        return ResponseCode.missingArgument;
      case "short_name":
        return ResponseCode.shortName;
      case "short_password":
        return ResponseCode.shortPassword;
      case "repeat_wrong":
        return ResponseCode.repeatNotMatch;
      //-------- 401 --------//
      case "wrong_password":
        return ResponseCode.wrongPassword;
      //-------- 403 --------//
      case "access_forbidden":
        return ResponseCode.accessForbidden;
      case "insufficient_permissions":
        return ResponseCode.insufficientPermissions;
      case "calendar_not_joinable":
        return ResponseCode.calendarNotJoinable;
      //-------- 404 --------//
      case "event_not_found":
        return ResponseCode.eventNotFound;
      case "user_not_found":
        return ResponseCode.userNotFound;
      case "calendar_not_found":
        return ResponseCode.calendarNotFound;
      case "member_not_found":
        return ResponseCode.memberNotFound;
      case "role_not_found":
        return ResponseCode.roleNotFound;
      case "voting_not_found":
        return ResponseCode.votingNotFound;
      case "choice_not_found":
        return ResponseCode.choiceNotFound;
      case "note_not_found":
        return ResponseCode.noteNotFound;
      //-------- Auth --------//
      case "invalid_token":
        return ResponseCode.tokenInvalid;
      case "token_required":
        return ResponseCode.tokenRequired;
      case "expired_token":
        return ResponseCode.tokenExpired;
      case "banned":
        return ResponseCode.userBanned;
      case "pass_changed":
        return ResponseCode.passwordChanged;
      case "auth_failed":
        return ResponseCode.authenticationFailed;
      case "token_still_valid":
        return ResponseCode.tokenStillValid;
      //-------- Invalid --------//
      case "invalid_number":
        return ResponseCode.invalidNumber;
      case "invalid_email":
        return ResponseCode.invalidEmail;
      case "invalid_title":
        return ResponseCode.invalidTitle;
      case "invalid_date":
        return ResponseCode.invalidDate;
      case "invalid_color":
        return ResponseCode.invalidColor;
      case "invalid_file":
        return ResponseCode.invalidFile;
      case "payload_too_large":
        return ResponseCode.payloadTooLarge;
      //-------- Unknown --------//
      default:
        return ResponseCode.unknown;
    }
  }
}

enum ResponseCode {
  success,

  assocUserAlreadyExists,
  calendarNotEmpty,
  lastMember,
  lastOwner,

  endBeforeStart,
  startAfter1900,

  alreadyVoted,
  noMultipleChoiceEnabled,
  invalidChoiceAmount,

  emailExistsError,
  missingArgument,
  shortName,
  shortPassword,
  repeatNotMatch,

  wrongPassword,

  accessForbidden,
  insufficientPermissions,
  calendarNotJoinable,

  eventNotFound,
  userNotFound,
  calendarNotFound,
  memberNotFound,
  roleNotFound,
  votingNotFound,
  choiceNotFound,
  noteNotFound,

  tokenInvalid,
  tokenRequired,
  tokenExpired,
  userBanned,
  passwordChanged,
  authenticationFailed,
  tokenStillValid,

  invalidNumber,
  invalidEmail,
  invalidTitle,
  invalidDate,
  invalidColor,
  invalidFile,
  payloadTooLarge,
  invalidAction,

  refreshToken,
  logout,
  timeout,
  internalError,

  unknown,
}