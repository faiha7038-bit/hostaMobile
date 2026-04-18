import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/presentation/screens/ambulance/ambulance_details.dart';
import 'package:hosta/presentation/screens/blood/blood_details.dart';
import 'package:hosta/presentation/screens/contact/contact.dart';
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

  // Logout function moved to SettingsPage
  // This function is removed from ProfilePage

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

  // Logout confirmation dialog removed from ProfilePage

  @override
  void dispose() {
    socket?.disconnect();
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? profileImageUrl = _getProfileImage();
    print("📸 Profile image URL: $profileImageUrl"); // Debug print

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // This centers the title
        backgroundColor: const Color(0xFF28A745),
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () => Navigator.pop(context),
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF28A745),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Profile Image - Eye icon removed
                          GestureDetector(
                            onTap: _navigateToViewProfile,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                color: Colors
                                    .white, // Background color for fallback
                              ),
                              child: ClipOval(
                                child: profileImageUrl != null
                                    ? Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              print(
                                                "❌ Error loading image: $error",
                                              );
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Color(0xFF28A745),
                                                ),
                                              );
                                            },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Color(
                                                          0xFF28A745,
                                                        ),
                                                      ),
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF28A745),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // User Name
                          Text(
                            _getSafeString(
                              userData['name'],
                              defaultValue: 'User Name',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // User Email
                          Text(
                            _getSafeString(
                              userData['email'],
                              defaultValue: 'email@example.com',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          //
                          //View Profile Button
                          if (userId != null && userId!.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _navigateToViewProfile,
                              icon: const Icon(Icons.person, size: 18),
                              label: const Text('View Full Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF28A745),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Options (Contact Information removed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // App Settings Section
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'App Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF28A745),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Settings Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                _buildProfileOption(
                                  icon: Icons.settings_outlined,
                                  title: 'Settings',
                                  subtitle: 'App settings and preferences',
                                  onTap: _navigateToSettings,
                                ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.lock_outline,
                                  title: 'Privacy',
                                  subtitle: 'Privacy policy and terms',
                                  onTap: _showPrivacyDialog,
                                ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.info_outline,
                                  title: 'About',
                                  subtitle: 'About this app',
                                  onTap: _showAboutDialog,
                                ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.water_drop_outlined,
                                  title: 'Blood',
                                  subtitle: 'About Blood',
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';

                                    if (userId.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please login first"),
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
                                  icon: Icons.local_taxi_outlined,
                                  title: 'Ambulance',
                                  subtitle: 'About ambulance',
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AmbulanceDetailsPage(
                                              userId: userId,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Support Section
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Support',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF28A745),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Support Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                _buildProfileOption(
                                  icon: Icons.headset_mic_outlined,
                                  title: 'Contact Us',
                                  subtitle: 'Get help and support',
                                  onTap: _showContactDialog,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Logout Button Removed from Profile Page
                          // Logout functionality is now in Settings page
                          const SizedBox(height: 20),

                          // App Version
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
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
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF28A745).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF28A745)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
