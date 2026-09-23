import 'package:cloud_firestore/cloud_firestore.dart';

/// Role of a member inside their household.
enum MemberRole { owner, member }

/// A member of a household, mirroring `households/{id}/members/{uid}`.
class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.upiId,
    required this.role,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? upiId;
  final MemberRole role;
  final DateTime joinedAt;

  factory HouseholdMember.fromMap(String id, Map<String, dynamic> map) =>
      HouseholdMember(
        id: id,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        phone: map['phone'] as String?,
        upiId: map['upiId'] as String?,
        role: MemberRole.values.asNameMap()[map['role']] ??
            MemberRole.member,
        joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        if (phone != null) 'phone': phone,
        if (upiId != null) 'upiId': upiId,
        'role': role.name,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  bool get isOwner => role == MemberRole.owner;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdMember &&
          other.id == id &&
          other.name == name &&
          other.role == role;

  @override
  int get hashCode => Object.hash(id, name, role);
}