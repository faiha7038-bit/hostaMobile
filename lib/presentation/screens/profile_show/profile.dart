import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/login_dialoge.dart';
import 'package:hosta/presentation/screens/ambulance/ambulance_details.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/blood/blood_details.dart';
import 'package:hosta/presentation/screens/contact/contact.dart';
import 'package:hosta/presentation/screens/document/documents.dart';
import 'package:hosta/presentation/screens/lab/lab.dart';
import 'package:hosta/presentation/screens/patient/patient.dart';
import 'package:hosta/presentation/screens/prescription/prescription.dart';
import 'package:hosta/presentation/screens/profile-edit/profile.dart';
import 'package:hosta/presentation/screens/privacy/privacy.dart';
import 'package:hosta/presentation/screens/about/about.dart';
import 'package:hosta/presentation/screens/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
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
      if (mounted) {
        setState(() => isLoading = false);
      }
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
      }
    } catch (e) {}
  }

  String _getSafeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) return value.toString();
    if (value is num) return value.toString();
    return defaultValue;
  }

  String? _getProfileImage() {
    final imageUrl = userData['imageUrl'];
    if (imageUrl is String && imageUrl.isNotEmpty) {
      return imageUrl;
    }
    return null;
  }

  Future<void> _navigateToViewProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';

    if (userId.isEmpty) {
      final shouldLogin = showLoginRequiredDialog(context);
      if (shouldLogin == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Signin(),
          ),
        );
        await _loadUserId();
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Profile(),
      ),
    );

    await _refreshUserData();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Responsive clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double settingsIconSize = _clamp(screenWidth * 0.06, 20, 32);
    final double avatarSize = _clamp(screenWidth * 0.28, 80, 150);
    final double avatarMaxSize = _clamp(screenWidth * 0.32, 100, 180);
    final double avatarMinSize = _clamp(screenWidth * 0.22, 60, 120);
    final double borderWidth = _clamp(screenWidth * 0.01, 1, 3);
    final double personIconSize = _clamp(screenWidth * 0.12, 30, 60);
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double nameFontSize = _clamp(screenWidth * 0.06, 20, 34);
    final double emailFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double viewProfileIconSize = _clamp(screenWidth * 0.045, 16, 24);
    final double viewProfileLabelSize = _clamp(screenWidth * 0.035, 12, 18);
    final double viewProfileButtonPadH = _clamp(screenWidth * 0.05, 16, 40);
    final double viewProfileButtonPadV = _clamp(screenHeight * 0.015, 8, 20);
    final double viewProfileButtonRadius = _clamp(screenWidth * 0.075, 20, 40);
    final double sectionTitleSize = _clamp(screenWidth * 0.045, 16, 24);
    final double cardElevation = _clamp(screenWidth * 0.005, 2, 8);
    final double cardRadius = _clamp(screenWidth * 0.0375, 10, 24);
    final double optionIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double optionTitleSize = _clamp(screenWidth * 0.04, 14, 22);
    final double optionSubtitleSize = _clamp(screenWidth * 0.035, 12, 18);
    final double optionTrailingSize = _clamp(screenWidth * 0.04, 14, 22);
    final double versionTextSize = _clamp(screenWidth * 0.03, 10, 16);
    final double listTileContentPadH = _clamp(screenWidth * 0.04, 12, 24);
    final double listTileContentPadV = _clamp(screenHeight * 0.005, 2, 10);
    final double iconContainerPadding = _clamp(screenWidth * 0.02, 6, 16);
    final double iconContainerRadius = _clamp(screenWidth * 0.025, 6, 16);
    final double spacingExtraSmall = _clamp(screenHeight * 0.01, 4, 12);
    final double spacingSmall = _clamp(screenHeight * 0.012, 6, 16);
    final double spacingMedium = _clamp(screenHeight * 0.02, 12, 24);
    final double spacingLarge = _clamp(screenHeight * 0.025, 16, 32);
    final double spacingXLarge = _clamp(screenHeight * 0.035, 20, 48);
    final double screenPadding = _clamp(screenWidth * 0.04, 12, 32);
    final double headerBottomRadius = _clamp(screenWidth * 0.08, 20, 40);

    String? profileImageUrl = _getProfileImage();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF28A745),
        elevation: 0,
        actions: [
          if ((userId ?? '').isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Colors.white,
                size: settingsIconSize,
              ),
              onPressed: _navigateToSettings,
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: loadingStrokeWidth,
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Header
                    Container(
                      width: screenWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(headerBottomRadius),
                          bottomRight: Radius.circular(headerBottomRadius),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: spacingMedium),
                          // Profile Image
                          GestureDetector(
                            onTap: _navigateToViewProfile,
                            child: Container(
                              width: avatarSize,
                              height: avatarSize,
                              constraints: BoxConstraints(
                                maxWidth: avatarMaxSize,
                                maxHeight: avatarMaxSize,
                                minWidth: avatarMinSize,
                                minHeight: avatarMinSize,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: borderWidth,
                                ),
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: profileImageUrl != null
                                    ? Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        width: avatarSize,
                                        height: avatarSize,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.person,
                                              size: personIconSize,
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
                                                strokeWidth: loadingStrokeWidth,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.person,
                                          size: personIconSize,
                                          color: const Color(0xFF28A745),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingMedium),
                          // User Name
                          Text(
                            _getSafeString(
                              userData['name'],
                              defaultValue: 'User Name',
                            ),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: spacingSmall),
                          // User Email
                          Text(
                            _getSafeString(
                              userData['email'],
                              defaultValue: 'email@example.com',
                            ),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: emailFontSize,
                            ),
                          ),
                          SizedBox(height: spacingLarge),
                          // View Profile Button
                          if (userId != null && userId!.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _navigateToViewProfile,
                              icon: Icon(
                                Icons.person,
                                size: viewProfileIconSize,
                              ),
                              label: Text(
                                'View Full Profile',
                                style: TextStyle(fontSize: viewProfileLabelSize),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF28A745),
                                padding: EdgeInsets.symmetric(
                                  horizontal: viewProfileButtonPadH,
                                  vertical: viewProfileButtonPadV,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    viewProfileButtonRadius,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: spacingXLarge),
                        ],
                      ),
                    ),

                    SizedBox(height: spacingLarge),

                    // Profile Options
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Settings Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'App Settings',
                              style: TextStyle(
                                fontSize: sectionTitleSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF28A745),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingSmall),

                          // Settings Card
                          Card(
                            elevation: cardElevation,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(cardRadius),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildProfileOption(
                                  icon: Icons.local_taxi,
                                  title: 'Ambulance',
                                  subtitle: 'About Your Registered Ambulances',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';
                                    if (userId.isEmpty) {
                                      showLoginRequiredDialog(context);
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
                                  icon: Icons.water_drop,
                                  title: 'Blood',
                                  subtitle: 'About Your Registered Blood ',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';
                                    if (userId.isEmpty) {
                                      showLoginRequiredDialog(context);
                                      return;
                                    }
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MyBloodDetailsPage(),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (result == true) {
                                      await _loadUserData();
                                    }
                                  },
                                ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.note_add,
                                  title: 'Prescription',
                                  subtitle: 'About Your Prescription',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';
                                    if (userId.isEmpty) {
                                      showLoginRequiredDialog(context);
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PrescriptionListScreen(
                                              userId: userId,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.note_sharp,
                                  title: 'Lab Report',
                                  subtitle: 'About Your Lab Reports ',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';
                                    if (userId.isEmpty) {
                                      showLoginRequiredDialog(context);
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
                                  icon: Icons.edit_document,
                                  title: ' My Documents',
                                  subtitle: 'keep and View Your Documents ',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';
                                    if (userId.isEmpty) {
                                      showLoginRequiredDialog(context);
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DocumentsTab(),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.person_add,
                                  title: 'Patient details',
                                  subtitle: 'View Patient Information',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    String userId =
                                        prefs.getString('userId') ?? '';
                                    if (userId.isEmpty) {
                                      showLoginRequiredDialog(context);
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PatientDetailsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 0),

                                if (userId != null && userId!.isNotEmpty) ...[
                                  const Divider(height: 0),
                                  _buildProfileOption(
                                    icon: Icons.settings,
                                    title: 'Settings',
                                    subtitle: 'App Settings and Preferences',
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    optionIconSize: optionIconSize,
                                    optionTitleSize: optionTitleSize,
                                    optionSubtitleSize: optionSubtitleSize,
                                    optionTrailingSize: optionTrailingSize,
                                    iconContainerPadding: iconContainerPadding,
                                    iconContainerRadius: iconContainerRadius,
                                    listTileContentPadH: listTileContentPadH,
                                    listTileContentPadV: listTileContentPadV,
                                    onTap: _navigateToSettings,
                                  ),
                                ],
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.lock,
                                  title: 'Privacy',
                                  subtitle: 'Privacy policy and Terms',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: _showPrivacyDialog,
                                ),
                                const Divider(height: 0),
                                _buildProfileOption(
                                  icon: Icons.info,
                                  title: 'About',
                                  subtitle: 'About this app',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: _showAboutDialog,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spacingLarge),

                          // Support Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Support',
                              style: TextStyle(
                                fontSize: sectionTitleSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF28A745),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingSmall),

                          // Support Card
                          Card(
                            elevation: cardElevation,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(cardRadius),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildProfileOption(
                                  icon: Icons.headset_mic,
                                  title: 'Contact Us',
                                  subtitle: 'Get help and support',
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  optionIconSize: optionIconSize,
                                  optionTitleSize: optionTitleSize,
                                  optionSubtitleSize: optionSubtitleSize,
                                  optionTrailingSize: optionTrailingSize,
                                  iconContainerPadding: iconContainerPadding,
                                  iconContainerRadius: iconContainerRadius,
                                  listTileContentPadH: listTileContentPadH,
                                  listTileContentPadV: listTileContentPadV,
                                  onTap: _showContactDialog,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: spacingLarge),

                          // App Version
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: versionTextSize,
                            ),
                          ),

                          SizedBox(height: spacingLarge),
                        ],
                      ),
                    ),
                    // Add a small bottom padding to ensure spacing
                    SizedBox(height: bottomPadding + spacingMedium),
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
    required double screenWidth,
    required double screenHeight,
    required double optionIconSize,
    required double optionTitleSize,
    required double optionSubtitleSize,
    required double optionTrailingSize,
    required double iconContainerPadding,
    required double iconContainerRadius,
    required double listTileContentPadH,
    required double listTileContentPadV,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(iconContainerPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF28A745).withOpacity(0.1),
          borderRadius: BorderRadius.circular(iconContainerRadius),
        ),
        child: Icon(icon, color: const Color(0xFF28A745), size: optionIconSize),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: optionTitleSize,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: optionSubtitleSize,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: optionTrailingSize),
      onTap: onTap,
      dense: screenHeight < 600 ? true : false,
      contentPadding: EdgeInsets.symmetric(
        horizontal: listTileContentPadH,
        vertical: listTileContentPadV,
      ),
    );
  }
}