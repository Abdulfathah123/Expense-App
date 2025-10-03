class UserModel {
  final String name;
  final String phone;
  final String address;
  final String email;
  final String password;
  UserModel({
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    required this.password,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'email': email,
    'password': password,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'],
    phone: json['phone'],
    address: json['address'],
    email: json['email'],
    password: json['password'],
  );
}
