import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirestoreTestPage(),
    );
  }
}

class FirestoreTestPage extends StatefulWidget {
  @override
  _FirestoreTestPageState createState() => _FirestoreTestPageState();
}

class _FirestoreTestPageState extends State<FirestoreTestPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveData() async {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      await _firestore.collection('testData').add({'text': text, 'timestamp': FieldValue.serverTimestamp()});
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data saved successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firestore Test")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: "Enter text", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _saveData, child: Text("Save to Firestore")),
          ],
        ),
      ),
    );
  }
}
