import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> readVariable(SecureVariable variable) async {
    String? content = await _storage.read(key: _variableToKey(variable));

    if(content == null) {
      return "";
    }

    return content;
  }

  Future<void> writeVariable(SecureVariable variable, String value) async {
    await _storage.write(key: _variableToKey(variable), value: value);
  }

  Future<void> wipeStorage() async {
    await _storage.deleteAll();
  }

  String _variableToKey(SecureVariable variable) {
    switch(variable) {
      case SecureVariable.hashedPassword:
        return "hash";
      case SecureVariable.authenticationToken:
        return "auth";
      case SecureVariable.refreshToken:
        return "refresh";
    }
  }
}

enum SecureVariable {
  hashedPassword,
  authenticationToken,
  refreshToken
}