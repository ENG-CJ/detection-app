class User {
  String? user_id;
  String mobile;
  String username, email, password;

  User(
      {required this.username,
      required this.email,
      required this.password,
      required this.mobile,
      this.user_id});

  factory User.fromJson(Map<String, dynamic> user) {
    return User(
        username: user['username'],
        email: user['email'],
        password: user['password'],
        mobile: user['mobile'],
        user_id: user['id']);
  }

  Map<String, dynamic> toJson() {
    return {
      "id": user_id,
      "name": username,
      "email": email,
      "password": password,
      "mobile": mobile,
      "action": "UpdateUser"
    };
  }
}
