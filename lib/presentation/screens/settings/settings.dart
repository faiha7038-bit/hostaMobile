import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/settings/accountsettings.dart';
import 'package:hosta/presentation/screens/settings/passwordManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isLoggedIn = false;
  @override
  void initState() {
    
    // TODO: implement initState
    super.initState();
      _checkLogin();
  }
  Future<void> _checkLogin() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  setState(() {
    isLoggedIn = token != null;
  });
}
  Future<void> _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // Store bloodId before clearing (if needed)
  final bloodId = prefs.getString('bloodId');
  
  // Clear only non-essential data
  await prefs.remove('userId');
  await prefs.remove('authToken');
  // Keep bloodId
  if (bloodId != null) {
    await prefs.setString('bloodId', bloodId);
  }
  
  // OR more simply: don't clear bloodId at all
  // await prefs.clear(); // ❌ DON'T use this
  
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Signin()),
      (route) => false,
    );
  }
}

// Future<void> _logout(BuildContext context) async {
  void _confirmLogout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(fontSize: screenWidth * 0.05),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: screenWidth * 0.05,
          ),
        ),
        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            // Password Manager
            if (isLoggedIn)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PasswordManagerPage(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.04,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.grey[200]!, width: screenWidth * 0.0025),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.green,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        "Password Manager",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: screenWidth * 0.04,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.015),

            // Delete Account
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountSettingsPage(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.04,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.grey[200]!, width: screenWidth * 0.0025),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        "Delete Account",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: screenWidth * 0.04,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.025),

            // Divider
            Divider(thickness: screenWidth * 0.0025),

            SizedBox(height: screenHeight * 0.015),

            // Logout Button
            GestureDetector(
              onTap: () => _confirmLogout(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.04,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.red[100]!, width: screenWidth * 0.0025),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: screenWidth * 0.04,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}