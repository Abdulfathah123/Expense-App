// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_storage/firebase_storage.dart';
//
// class EditProfilePage extends StatefulWidget {
//   @override
//   _EditProfilePageState createState() => _EditProfilePageState();
// }
//
// class _EditProfilePageState extends State<EditProfilePage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ImagePicker _picker = ImagePicker();
//
//   User? user;
//   String username = "";
//   String phone = "";
//   String address = "";
//   String profileImageUrl = "";
//   File? _image;
//
//   @override
//   void initState() {
//     super.initState();
//     user = _auth.currentUser;
//     _fetchUserData();
//   }
//
//   void _fetchUserData() async {
//     if (user != null) {
//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();
//       if (userDoc.exists) {
//         setState(() {
//           username = userDoc['name'] ?? "";
//           phone = userDoc['phone'] ?? "";
//           address = userDoc['address'] ?? "";
//           profileImageUrl = userDoc['profileImageUrl'] ?? "";
//         });
//       }
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//       _uploadImage();
//     }
//   }
//
//   Future<void> _uploadImage() async {
//     if (_image == null || user == null) return;
//     try {
//       final ref = FirebaseStorage.instance.ref().child('profile_images').child('${user!.uid}.jpg');
//       await ref.putFile(_image!);
//       final url = await ref.getDownloadURL();
//       setState(() {
//         profileImageUrl = url;
//       });
//       await _firestore.collection('users').doc(user!.uid).update({'profileImageUrl': url});
//     } catch (e) {
//       print("Error uploading image: $e");
//     }
//   }
//
//   Future<void> _updateUserData() async {
//     if (user != null) {
//       await _firestore.collection('users').doc(user!.uid).update({
//         'name': username,
//         'phone': phone,
//         'address': address,
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Edit Profile")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: _pickImage,
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: profileImageUrl.isNotEmpty
//                     ? NetworkImage(profileImageUrl)
//                     : AssetImage('Assets/profile.jpg') as ImageProvider,
//                 child: _image == null ? Icon(Icons.camera_alt, size: 30, color: Colors.white) : null,
//               ),
//             ),
//             SizedBox(height: 20),
//             TextField(
//               decoration: InputDecoration(labelText: "Username"),
//               onChanged: (value) => username = value,
//               controller: TextEditingController(text: username),
//             ),
//             TextField(
//               decoration: InputDecoration(labelText: "Phone Number"),
//               onChanged: (value) => phone = value,
//               keyboardType: TextInputType.phone,
//               controller: TextEditingController(text: phone),
//             ),
//             TextField(
//               decoration: InputDecoration(labelText: "Address"),
//               onChanged: (value) => address = value,
//               controller: TextEditingController(text: address),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _updateUserData,
//               child: Text("Save Changes"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
