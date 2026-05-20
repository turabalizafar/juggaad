class UserProfile {
  final String uid;
  final String phoneNumber;
  final String? displayName;
  final String createdAt;

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    this.displayName,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      displayName: json['display_name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
