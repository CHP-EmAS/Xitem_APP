import 'dart:io';
import 'package:flutter/material.dart';

class AvatarImageProvider {
  static ImageProvider get(File? avatarFile) {
    if(avatarFile == null) {
      return const AssetImage("images/avatar.png");
    }

    return FileImage(avatarFile);
  }
}