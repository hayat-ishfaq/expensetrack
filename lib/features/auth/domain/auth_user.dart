/// Firebase identity of the signed-in user, independent of the Firestore
/// profile document.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.uid == uid &&
          other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);
}