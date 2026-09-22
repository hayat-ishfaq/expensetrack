import 'package:cloud_firestore/cloud_firestore.dart';

/// The authenticated user's profile, mirroring the `users/{uid}` document.
///
/// `householdId` is `null` until the user creates or joins a flat; that
/// transition is what routes the user to household setup vs. the dashboard.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.householdId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  /// The household this user belongs to, or `null` when they have none yet.
  final String? householdId;
  final DateTime createdAt;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        householdId: map['householdId'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        if (householdId != null) 'householdId': householdId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AppUser copyWith({String? name, String? email, String? photoUrl}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        householdId: householdId,
        createdAt: createdAt,
      );

  AppUser withHouseholdId(String? newHouseholdId) => AppUser(
        id: id,
        name: name,
        email: email,
        photoUrl: photoUrl,
        householdId: newHouseholdId,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.householdId == householdId;

  @override
  int get hashCode => Object.hash(id, name, email, householdId);
}