import 'package:flutter/material.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/app_user_repository.dart';

class AppUserViewModel extends ChangeNotifier {
  final AppUserRepository _userRepository;
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  AppUserViewModel({required AppUserRepository userRepository})
      : _userRepository = userRepository;

  // Fetch the user and store it in the currentUser
  Future<void> fetchUser(String userId) async {
    _currentUser = await _userRepository.getUserById(userId);
    notifyListeners();
  }
}
