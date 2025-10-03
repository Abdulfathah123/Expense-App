import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:int_tst/home_page.dart';

import 'package:int_tst/expense_section/expense_add_page.dart';
import 'package:int_tst/expense_section/expense_details.dart';
import 'package:int_tst/expense_section/finance_page.dart';
import 'package:int_tst/chart_section/monthly.dart';
import 'package:int_tst/login_section/profile.dart';
import 'package:int_tst/expense_section/savings.dart';
import 'package:int_tst/home_page.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  List<Widget> pages = [
    MainPage(),
    ExpenseIncomePage(),
    Monthly(),
    ProfilePage(),
  ];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // return false;
        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        body: pages[currentIndex],
        bottomNavigationBar: ConvexAppBar(
          key: ValueKey(currentIndex),
          // cornerRadius: 20,
          style: TabStyle
              .react, // Choose from TabStyle options (e.g., fixed, react, flip, etc.)
          initialActiveIndex: currentIndex,
          onTap: (int index) {
            setState(() {
              currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          activeColor: Colors.blue,
          color: Colors.black,
          items: [
            TabItem(icon: Icons.home),
            TabItem(icon: Icons.add ),
            TabItem(icon: Icons.pie_chart),
            TabItem(icon: Icons.person),
          ],
        ),
      ),
    );
  }
}
