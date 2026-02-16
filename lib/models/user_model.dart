class UserModel {
  final String uid;
  final String email;
  final String plan;
  final bool validated;
  final DateTime? expiry;

  UserModel({
    required this.uid,
    required this.email,
    required this.plan,
    required this.validated,
    this.expiry,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      plan: data['plan'] ?? 'free',
      validated: data['validated'] ?? false,
      expiry: data['expiry']?.toDate(),
    );
  }
}