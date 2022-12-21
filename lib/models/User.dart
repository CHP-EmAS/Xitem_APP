import 'dart:io';

class User {
  User(this._id, this.name, this.birthday, this._role, this.avatar);

  final String _id;
  String name;
  DateTime? birthday;
  final String _role;
  File? avatar;

  String get id => _id;
  String get role => _role;
}

class AuthenticatedUser extends User {
  AuthenticatedUser(User userInfo, this._email, this._registeredAt)
      : super(userInfo.id, userInfo.name, userInfo.birthday, userInfo._role, userInfo.avatar);

  final String _email;
  final DateTime _registeredAt;

  String get email => _email;
  DateTime get registeredAt => _registeredAt;
}
