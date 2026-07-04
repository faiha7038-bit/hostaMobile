// import 'package:flutter/material.dart';
// import 'package:hosta/presentation/screens/auth/signin.dart';
// import 'package:hosta/presentation/screens/settings/accountsettings.dart';
// import 'package:hosta/presentation/screens/settings/passwordManager.dart';
// import 'package:hosta/services/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   bool isLoggedIn = false;
//   final ApiService apiService=ApiService();
//   @override
//   void initState() {
    
//     // TODO: implement initState
//     super.initState();
//       _checkLogin();
//   }
//   Future<void> _checkLogin() async {
//   final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString('authToken');

//   setState(() {
//     isLoggedIn = token != null;
//   });
// }
// Future<void> logout(BuildContext context) async {
//   print("LOGOUT CLICKED");

//   final navigator = Navigator.of(context, rootNavigator: true);

//   try {
//     await apiService.logout();
//   } catch (e) {
//     print("LOGOUT API ERROR (ignoring): $e");
//   }

//   // Clear ALL stored data (optional)
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.clear(); 
 

//   // If you have other storage like Hive, clear those as well
//   // await Hive.box('donorsBox').clear();

//   print("ALL DATA CLEARED");

//   // Navigate to Signin and remove all history
//   navigator.pushAndRemoveUntil(
//     MaterialPageRoute(builder: (_) => Signin()),
//     (route) => false,
//   );
// }

// // Future<void> _(BuildContext context) async {
//   void _confirmLogout(BuildContext context) {
//     print("confirmLogout called");
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
    
//  showDialog(
//   context: context,
//   useRootNavigator: true,
//   builder: (context) {
//     return AlertDialog(
//       title: const Text("Logout"),
//       content: const Text("Are you sure you want to logout?"),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text("Cancel",style: TextStyle(color: Colors.grey),),
//         ),
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//             logout(context);
//           },
//           child: const Text("Logout",style: TextStyle(color:Colors.red),),
//         ),
//       ],
//     );
//   },
// );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
    
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: Icon(
//             Icons.arrow_back_ios_new_rounded,
//             color: Colors.white,
//             size: screenWidth * 0.05,
//           ),
//         ),
//         title: Text(
//           "Settings",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: screenWidth * 0.06,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(screenWidth * 0.05),
//         child: Column(
//           children: [
//             // Password Manager
//             if (isLoggedIn)
//             GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const PasswordManagerPage(),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(
//                   vertical: screenHeight * 0.02,
//                   horizontal: screenWidth * 0.04,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                   border: Border.all(color: Colors.grey[200]!, width: screenWidth * 0.0025),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.lock_outline_rounded,
//                       color: Colors.green,
//                       size: screenWidth * 0.06,
//                     ),
//                     SizedBox(width: screenWidth * 0.04),
//                     Expanded(
//                       child: Text(
//                         "Password Manager",
//                         style: TextStyle(
//                           fontSize: screenWidth * 0.04,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios_rounded,
//                       size: screenWidth * 0.04,
//                       color: Colors.grey,
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: screenHeight * 0.015),

//             // Delete Account
//             GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const AccountSettingsPage(),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(
//                   vertical: screenHeight * 0.02,
//                   horizontal: screenWidth * 0.04,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                   border: Border.all(color: Colors.grey[200]!, width: screenWidth * 0.0025),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.delete_outline_rounded,
//                       color: Colors.red,
//                       size: screenWidth * 0.06,
//                     ),
//                     SizedBox(width: screenWidth * 0.04),
//                     Expanded(
//                       child: Text(
//                         "Delete Account",
//                         style: TextStyle(
//                           fontSize: screenWidth * 0.04,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.red,
//                         ),
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios_rounded,
//                       size: screenWidth * 0.04,
//                       color: Colors.grey,
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: screenHeight * 0.025),

//             // Divider
//             Divider(thickness: screenWidth * 0.0025),

//             SizedBox(height: screenHeight * 0.015),

//             // Logout Button
//            InkWell(
//   onTap: () {
//     debugPrint("Logout tapped");
//     _confirmLogout(context);
//   },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(
//                   vertical: screenHeight * 0.02,
//                   horizontal: screenWidth * 0.04,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.red[50],
//                   borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                   border: Border.all(color: Colors.red[100]!, width: screenWidth * 0.0025),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.logout_rounded,
//                       color: Colors.red,
//                       size: screenWidth * 0.06,
//                     ),
//                     SizedBox(width: screenWidth * 0.04),
//                     Expanded(
//                       child: Text(
//                         "Logout",
//                         style: TextStyle(
//                           fontSize: screenWidth * 0.04,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.red,
//                         ),
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios_rounded,
//                       size: screenWidth * 0.04,
//                       color: Colors.grey,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/settings/accountsettings.dart';
import 'package:hosta/presentation/screens/settings/passwordManager.dart';
import 'package:hosta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isLoggedIn = false;
  final ApiService apiService = ApiService();

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

  Future<void> logout(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      await apiService.logout();
    } catch (e) {
      // Ignore API errors during logout
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Signin()),
      (route) => false,
    );
  }

  void _confirmLogout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          title: Text(
            "Logout",
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.05 
                  : isMediumScreen 
                      ? screenWidth * 0.04 
                      : screenWidth * 0.028,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.04 
                  : isMediumScreen 
                      ? screenWidth * 0.032 
                      : screenWidth * 0.025,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isSmallScreen 
                      ? screenWidth * 0.04 
                      : isMediumScreen 
                          ? screenWidth * 0.032 
                          : screenWidth * 0.025,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                logout(context);
              },
              child: Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isSmallScreen 
                      ? screenWidth * 0.04 
                      : isMediumScreen 
                          ? screenWidth * 0.032 
                          : screenWidth * 0.025,
                ),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenHeight * 0.01,
          ),
          buttonPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.01,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

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
            size: isSmallScreen 
                ? screenWidth * 0.05 
                : isMediumScreen 
                    ? screenWidth * 0.04 
                    : screenWidth * 0.03,
          ),
        ),
        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen 
                ? screenWidth * 0.06 
                : isMediumScreen 
                    ? screenWidth * 0.045 
                    : screenWidth * 0.032,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        toolbarHeight: isSmallScreen 
            ? kToolbarHeight 
            : isMediumScreen 
                ? kToolbarHeight * 1.1 
                : kToolbarHeight * 1.2,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen 
              ? screenWidth * 0.05 
              : isMediumScreen 
                  ? screenWidth * 0.08 
                  : screenWidth * 0.12,
          vertical: screenHeight * 0.02,
        ),
        child: isLargeScreen
            ? _buildLargeScreenLayout(screenWidth, screenHeight)
            : _buildSmallMediumScreenLayout(screenWidth, screenHeight),
      ),
    );
  }

  Widget _buildSmallMediumScreenLayout(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Column(
      children: [
        // Password Manager
        if (isLoggedIn)
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.green,
            title: "Password Manager",
            titleColor: Colors.black87,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasswordManagerPage(),
                ),
              );
            },
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),

        if (isLoggedIn)
          SizedBox(height: screenHeight * 0.015),

        // Delete Account
        _buildMenuItem(
          icon: Icons.delete_outline_rounded,
          iconColor: Colors.red,
          title: "Delete Account",
          titleColor: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountSettingsPage(),
              ),
            );
          },
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),

        SizedBox(height: screenHeight * 0.025),

        // Divider
        Divider(
          thickness: screenWidth * 0.0025,
          color: Colors.grey[300],
        ),

        SizedBox(height: screenHeight * 0.015),

        // Logout Button
        _buildMenuItem(
          icon: Icons.logout_rounded,
          iconColor: Colors.red,
          title: "Logout",
          titleColor: Colors.red,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[100]!,
          onTap: () {
            _confirmLogout(context);
          },
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ],
    );
  }

  Widget _buildLargeScreenLayout(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel - Menu Items
        Expanded(
          flex: 1,
          child: Column(
            children: [
              if (isLoggedIn)
                _buildMenuItem(
                  icon: Icons.lock_outline_rounded,
                  iconColor: Colors.green,
                  title: "Password Manager",
                  titleColor: Colors.black87,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordManagerPage(),
                      ),
                    );
                  },
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
              if (isLoggedIn)
                SizedBox(height: screenHeight * 0.015),
              
              _buildMenuItem(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red,
                title: "Delete Account",
                titleColor: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsPage(),
                    ),
                  );
                },
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              
              SizedBox(height: screenHeight * 0.025),
              
              Divider(
                thickness: screenWidth * 0.0025,
                color: Colors.grey[300],
              ),
              
              SizedBox(height: screenHeight * 0.015),
              
              _buildMenuItem(
                icon: Icons.logout_rounded,
                iconColor: Colors.red,
                title: "Logout",
                titleColor: Colors.red,
                backgroundColor: Colors.red[50]!,
                borderColor: Colors.red[100]!,
                onTap: () {
                  _confirmLogout(context);
                },
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        
        // Right Panel - Info/Additional Settings
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(
              isSmallScreen 
                  ? screenWidth * 0.04 
                  : screenWidth * 0.03,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(
                color: Colors.grey[200]!,
                width: screenWidth * 0.0025,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  "Manage your account preferences, security, and privacy settings.",
                  style: TextStyle(
                    fontSize: screenWidth * 0.02,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: screenWidth * 0.025,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          "Logged in as ${isLoggedIn ? 'User' : 'Guest'}",
                          style: TextStyle(
                            fontSize: screenWidth * 0.02,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final isSmallScreen = screenWidth < 600;
    final defaultBgColor = Colors.grey[50]!;
    final defaultBorderColor = Colors.grey[200]!;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen 
              ? screenHeight * 0.02 
              : screenHeight * 0.018,
          horizontal: isSmallScreen 
              ? screenWidth * 0.04 
              : screenWidth * 0.035,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? defaultBgColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: borderColor ?? defaultBorderColor,
            width: screenWidth * 0.0025,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: isSmallScreen 
                  ? screenWidth * 0.06 
                  : screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen 
                      ? screenWidth * 0.04 
                      : screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: isSmallScreen 
                  ? screenWidth * 0.04 
                  : screenWidth * 0.035,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}