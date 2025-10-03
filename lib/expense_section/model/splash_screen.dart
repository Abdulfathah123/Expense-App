import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/Home_page.dart';
import 'package:int_tst/expense_section/botton_nav.dart';
import 'package:int_tst/login_section/login.dart';
import 'package:int_tst/home_page.dart';
import 'package:int_tst/main.dart';
import 'package:int_tst/res/assets_res.dart';

void main() {
  runApp(const MyApp());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreen();
}

class _SplashScreen extends State<SplashScreen> {
  final String isLogged = GetStorage().read('uid') ?? '';
  final _box = GetStorage();
  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(seconds: 2),
      () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  isLogged != '' ? BottomNavScreen() : Login()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEEEE),
      body: Center(
        child: Image.asset(
          'Assets/FinTrack.png',
          height: 350,
          width: 350,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
