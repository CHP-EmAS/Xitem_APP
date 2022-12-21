import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<String> readVariable(SecureVariable variable) async {
    String? content = await _storage.read(key: _variableToKey(variable));

    if(content == null) {
      return "";
    }

    return content;
  }

  static Future<void> writeVariable(SecureVariable variable, String value) async {
    await _storage.write(key: _variableToKey(variable), value: value);
  }

  static Future<void> wipeStorage() async {
    await _storage.deleteAll();
  }

  static String _variableToKey(SecureVariable variable) {
    switch(variable) {
      case SecureVariable.hashedPassword:
        return "hash";
      case SecureVariable.authToken:
        return "auth";
      case SecureVariable.refreshToken:
        return "refresh";
    }
  }
}

enum SecureVariable {
  hashedPassword,
  authToken,
  refreshToken
}