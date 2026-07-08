import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/device.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/settings/accountsettings.dart';
import 'package:hosta/presentation/screens/settings/passwordManager.dart';
import 'package:hosta/providers/blood-donateprovider.dart';
import 'package:hosta/providers/blood_details_provider.dart';
import 'package:hosta/services/api_service.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool isLoggedIn = false;
  final ApiService apiService=ApiService();
  @override
  void initState() {
    
   
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
Future<void> logout(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context, rootNavigator: true);

final deviceId = await getDeviceId();

  // Read the current userId
  final userId = ref.read(userIdProvider);

  try {
   
   final userId = ref.read(userIdProvider);
final deviceId = await getDeviceId();

await apiService.logout(
  userId,
  {
    "deviceId": deviceId,
  },
);
  } catch (_) {}


  SocketService().disconnect();

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();


  ref.invalidate(bloodProvider);
  ref.invalidate(userIdProvider);

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const Signin()),
    (route) => false,
  );
}


void _confirmLogout(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",style: TextStyle(color: Colors.grey),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              logout(context, ref);
            },
            child: const Text("Logout",style: TextStyle(color: Colors.red),),
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
           InkWell(
 onTap: () {
  _confirmLogout(context, ref);
},
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