import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/presentation/screens/ambulance/ambulance_details.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/blood/blood_details.dart';
import 'package:hosta/presentation/screens/contact/contact.dart';
import 'package:hosta/presentation/screens/history/myhistory.dart';
import 'package:hosta/presentation/screens/lab/lab.dart';
import 'package:hosta/presentation/screens/prescription.dart';
import 'package:hosta/presentation/screens/profile-edit/profile.dart';
import 'package:hosta/presentation/screens/privacy/privacy.dart';
import 'package:hosta/presentation/screens/about/about.dart';
import 'package:hosta/presentation/screens/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../services/api_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  String? userId;
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _setupSocketListener();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');

      if (mounted) {
        setState(() {
          userId = storedUserId;
        });
      }

      if (userId != null && userId!.isNotEmpty) {
        await _loadUserData();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error loading user ID: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      setState(() => isLoading = true);
      final response = await ApiService().getAUser(userId!);

      if (mounted) {
        setState(() {
          userData = response.data['data'] ?? {};
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error loading user data: $e");
      if (mounted) {
        showTopSnackBar(context, "Error loading profile data", isError: true);
        setState(() => isLoading = false);
      }
    }
  }

  void _setupSocketListener() {
    try {
      const String serverUrl = 'https://www.zorrowtek.in';

      socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      });

      socket!.on('connect', (_) {
        print("✅ Profile page connected to server");
        if (userId != null && userId!.isNotEmpty) {
          socket!.emit('joinUserRoom', {'userId': userId});
        }
      });

      socket!.on('profile', (data) {
        print('📡 Profile update received: $data');
        final profileUserId = data['userId']?.toString();

        if (profileUserId == userId) {
          _refreshUserData();
        }
      });

      socket!.connect();
    } catch (e) {
      print('❌ Error setting up socket: $e');
    }
  }

  Future<void> _refreshUserData() async {
    if (userId == null || userId!.isEmpty) return;

    try {
      final response = await ApiService().getAUser(userId!);
      if (mounted) {
        setState(() {
          userData = response.data['data'] ?? {};
        });
        showTopSnackBar(context, "Profile updated successfully");
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    }
  }

  // Helper method to safely extract string values
  String _getSafeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) return value.toString();
    if (value is num) return value.toString();
    return defaultValue;
  } 

  // Helper method to safely extract profile image URL based on your structure
  // picture: { imageUrl: { type: String }, public_id: { type: String } }
  String? _getProfileImage() {
    final picture = userData['picture'];

    if (picture == null) return null;

    // Handle the case where picture is a Map with imageUrl field
    if (picture is Map) {
      // Check if imageUrl exists in the picture map
      if (picture['imageUrl'] != null) {
        final imageUrl = picture['imageUrl'];
        if (imageUrl is String && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      // Also check if picture itself is a string (fallback)
      if (picture['url'] is String) {
        return picture['url'] as String;
      }
    }

    // If picture is directly a string (fallback for backward compatibility)
    if (picture is String && picture.isNotEmpty) {
      return picture;
    }

    return null;
  }

  void _navigateToViewProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Profile()));
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _showAboutDialog() {
    showDialog(context: context, builder: (context) => const About());
  }

  void _showContactDialog() {
    showDialog(context: context, builder: (context) => const Contact());
  }

  void _showPrivacyDialog() {
    showDialog(context: context, builder: (context) => const Privacy());
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    String? profileImageUrl = _getProfileImage();
    print("📸 Profile image URL: $profileImageUrl"); // Debug print

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF28A745),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: screenWidth * 0.06),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - kToolbarHeight - topPadding,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                          width: screenWidth,
                          decoration: const BoxDecoration(
                            color: Color(0xFF28A745),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              // Profile Image
                              GestureDetector(
                                onTap: _navigateToViewProfile,
                                child: Container(
                                  width: screenWidth * 0.28,
                                  height: screenWidth * 0.28,
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.32,
                                    maxHeight: screenWidth * 0.32,
                                    minWidth: screenWidth * 0.22,
                                    minHeight: screenWidth * 0.22,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: screenWidth * 0.01,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: ClipOval(
                                    child: profileImageUrl != null
                                        ? Image.network(
                                            profileImageUrl,
                                            fit: BoxFit.cover,
                                            width: screenWidth * 0.28,
                                            height: screenWidth * 0.28,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  print(
                                                    "❌ Error loading image: $error",
                                                  );
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: Icon(
                                                      Icons.person,
                                                      size: screenWidth * 0.12,
                                                      color: const Color(0xFF28A745),
                                                    ),
                                                  );
                                                },
                                            loadingBuilder:
                                                (context, child, loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        color: const Color(0xFF28A745),
                                                        strokeWidth: screenWidth * 0.008,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.person,
                                              size: screenWidth * 0.12,
                                              color: const Color(0xFF28A745),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              // User Name
                              Text(
                                _getSafeString(
                                  userData['name'],
                                  defaultValue: 'User Name',
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              // User Email
                              Text(
                                _getSafeString(
                                  userData['email'],
                                  defaultValue: 'email@example.com',
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.025),
                              //View Profile Button
                              if (userId != null && userId!.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: _navigateToViewProfile,
                                  icon: Icon(Icons.person, size: screenWidth * 0.045),
                                  label: Text(
                                    'View Full Profile',
                                    style: TextStyle(fontSize: screenWidth * 0.035),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF28A745),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05,
                                      vertical: screenHeight * 0.015,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(screenWidth * 0.075),
                                    ),
                                  ),
                                ),
                              SizedBox(height: screenHeight * 0.035),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // Profile Options
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                          child: Column(
                            children: [
                              // App Settings Section
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'App Settings',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF28A745),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.012),

                              // Settings Card
                              Card(
                                elevation: screenWidth * 0.005,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                                ),
                                child: Column(
                                  children: [
                                    _buildProfileOption(
                                      icon: Icons.local_taxi_outlined,
                                      title: 'Ambulance',
                                      subtitle: 'About ambulance',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: () async {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        String userId =
                                            prefs.getString('userId') ?? '';
                                        if (userId.isEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Login Required", style: TextStyle(fontSize: screenWidth * 0.045)),
                                              content: Text(
                                                "Please login first",
                                                style: TextStyle(fontSize: screenWidth * 0.04),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text("Cancel", style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            Signin(),
                                                      ),
                                                    );
                                                  },
                                                  child: Text("Login", style: TextStyle(color: Colors.green, fontSize: screenWidth * 0.04)),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AmbulanceDetailsPage(),
                                          ),
                                        );
                                      },
                                    ),

                                    const Divider(height: 0),
                                    _buildProfileOption(
                                      icon: Icons.water_drop_outlined,
                                      title: 'Blood',
                                      subtitle: 'About Blood',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: () async {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        String userId =
                                            prefs.getString('userId') ?? '';

                                        if (userId.isEmpty) {
                                           showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Login Required", style: TextStyle(fontSize: screenWidth * 0.045)),
                                              content: Text(
                                                "Please login first",
                                                style: TextStyle(fontSize: screenWidth * 0.04),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text("Cancel", style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            Signin(),
                                                      ),
                                                    );
                                                  },
                                                  child: Text("Login", style: TextStyle(color: Colors.green, fontSize: screenWidth * 0.04)),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MyBloodDetailsPage(userId: userId),
                                          ),
                                        );
                                      },
                                    ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  
                                  icon: Icons.note_add_outlined,
                                  title: 'Prescription',
                                  subtitle: 'About prescription',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';
                                    if (userId.isEmpty) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text("Login Required", style: TextStyle(fontSize: screenWidth * 0.045)),
                                          content: Text(
                                            "Please login first",
                                            style: TextStyle(fontSize: screenWidth * 0.04),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text("Cancel", style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Signin(),
                                                        
                                                  ),
                                                );
                                              },
                                              child: Text("Login", style: TextStyle(color: Colors.green, fontSize: screenWidth * 0.04)),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PrescriptionDetailsScreen(
                                              // userId: userId,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                     const Divider(height: 0),
                                     _buildProfileOption(
                                      icon: Icons.note_sharp,
                                      title: 'Lab Report',
                                      subtitle: 'Lab report details',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: () async {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        String userId =
                                            prefs.getString('userId') ?? '';

                                        if (userId.isEmpty) {
                                           showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Login Required", style: TextStyle(fontSize: screenWidth * 0.045)),
                                              content: Text(
                                                "Please login first",
                                                style: TextStyle(fontSize: screenWidth * 0.04),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text("Cancel", style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            Signin(),
                                                      ),
                                                    );
                                                  },
                                                  child: Text("Login", style: TextStyle(color: Colors.green, fontSize: screenWidth * 0.04)),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LabReport(),
                                          ),
                                        );
                                      },
                                    ),
                                    const Divider(height: 0),
                                      _buildProfileOption(
                                      icon: Icons.history_outlined,
                                      title: 'My History',
                                      subtitle: 'view details',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: () async {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        String userId =
                                            prefs.getString('userId') ?? '';

                                        if (userId.isEmpty) {
                                           showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text("Login Required", style: TextStyle(fontSize: screenWidth * 0.045)),
                                              content: Text(
                                                "Please login first",
                                                style: TextStyle(fontSize: screenWidth * 0.04),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text("Cancel", style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.04)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            Signin(),
                                                      ),
                                                    );
                                                  },
                                                  child: Text("Login", style: TextStyle(color: Colors.green, fontSize: screenWidth * 0.04)),
                                                ),
                                              ],
                                            ),
                                          );
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const HistoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const Divider(height: 0),

                                    _buildProfileOption(
                                      icon: Icons.settings_outlined,
                                      title: 'Settings',
                                      subtitle: 'App settings and preferences',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: _navigateToSettings,
                                    ),
                                    const Divider(height: 0),
                                    _buildProfileOption(
                                      icon: Icons.lock_outline,
                                      title: 'Privacy',
                                      subtitle: 'Privacy policy and terms',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: _showPrivacyDialog,
                                    ),
                                    const Divider(height: 0),
                                    _buildProfileOption(
                                      icon: Icons.info_outline,
                                      title: 'About',
                                      subtitle: 'About this app',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: _showAboutDialog,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.025),
                              // Support Section
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Support',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF28A745),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.012),

                              // Support Card
                              Card(
                                elevation: screenWidth * 0.005,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                                ),
                                child: Column(
                                  children: [
                                    _buildProfileOption(
                                      icon: Icons.headset_mic_outlined,
                                      title: 'Contact Us',
                                      subtitle: 'Get help and support',
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      onTap: _showContactDialog,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.025),

                              // App Version
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.03),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: const Color(0xFF28A745).withOpacity(0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
        ),
        child: Icon(icon, color: const Color(0xFF28A745), size: screenWidth * 0.055),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.04,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600], 
          fontSize: screenWidth * 0.035,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
      onTap: onTap,
      dense: screenHeight < 600 ? true : false,
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.005,
      ),
    );
  }
}