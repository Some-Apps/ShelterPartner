import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelter_partner/models/account_settings.dart';
import 'package:shelter_partner/models/filter_group.dart';
import 'package:shelter_partner/views/pages/main_filter_page.dart';

class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  final Timestamp lastActivity;

  final String type;
  final String shelterId;
  final AccountSettings? accountSettings;
  final FilterElement? userFilter;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,

    required this.lastActivity,

    required this.type,
    required this.shelterId,
    required this.accountSettings,
    this.userFilter,
  });

  // Factory constructor to create AppUser from Firestore document
  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Reconstruct filter group (similar to how it's done in AccountSettings)
    FilterGroup reconstructFilterGroup(Map<String, dynamic> json) {
      List<FilterElement> elements = [];
      if (json.containsKey('filterElements')) {
        elements = (json['filterElements'] as List)
            .map((e) => FilterElement.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      LogicalOperator logicalOperator = LogicalOperator.and; // Default to AND
      if (json.containsKey('operatorsBetween') &&
          (json['operatorsBetween'] as Map).values.any((v) => v == 'or')) {
        logicalOperator = LogicalOperator.or;
      }

      return FilterGroup(
        logicalOperator: logicalOperator,
        elements: elements,
      );
    }

    // Deserialize userFilter (if it exists in Firestore)
    FilterElement? userFilter;
    if (data.containsKey('userFilter') && data['userFilter'] != null) {
      final userFilterData = data['userFilter'] as Map<String, dynamic>;
      userFilter = reconstructFilterGroup(userFilterData);
    }

    return AppUser(
      id: doc.id,
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      lastActivity: data['lastActivity'],
      type: data['type'],
      shelterId: data['shelterID'],
      accountSettings: AccountSettings.fromMap(data['accountSettings'] ?? {}),
      userFilter: userFilter, // Assign the deserialized userFilter here
    );
  }

  // CopyWith method to create a copy of AppUser with optional changes
  AppUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    Timestamp? lastActivity,
    int? averageLogDuration,
    int? totalTimeLoggedWithAnimals,
    String? type,
    String? shelterId,
    AccountSettings? accountSettings,
    FilterElement? userFilter,
  }) {
    return AppUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      lastActivity: this.lastActivity,
      type: type ?? this.type,
      shelterId: shelterId ?? this.shelterId,
      accountSettings: accountSettings ?? this.accountSettings,
      userFilter: userFilter ?? this.userFilter,
    );
  }
}
