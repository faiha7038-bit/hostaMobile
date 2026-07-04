import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/profile-provider.dart';
import 'package:hosta/services/socket-service.dart';
import 'dart:io';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  @override
  ConsumerState<Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  late Function(dynamic) _onUserEvent;

  @override
  void initState() {
    super.initState();
    ref.read(userDataProvider.notifier).loadUserIdAndProfile();
    _onUserEvent = (data) {
      if (mounted) {
        ref.read(userDataProvider.notifier).loadProfile();
      }
    };
    SocketService().addListener(
      [
        "USER_REGISTERED",
        "USER_UPDATED",
        "USER_DELETED",
      ],
      _onUserEvent,
    );
  }

  @override
  void dispose() {
    SocketService().removeListener("USER_REGISTERED", _onUserEvent);
    SocketService().removeListener("USER_UPDATED", _onUserEvent);
    SocketService().removeListener("USER_DELETED", _onUserEvent);
    super.dispose();
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double closeIconSize = _clamp(screenWidth * 0.08, 24, 48);
    final double topPosition = _clamp(screenHeight * 0.05, 20, 60);
    final double rightPosition = _clamp(screenWidth * 0.04, 12, 32);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image, size: _clamp(screenWidth * 0.25, 60, 150), color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: topPosition,
              right: rightPosition,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: closeIconSize),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImageFromFile(BuildContext context, File file) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double closeIconSize = _clamp(screenWidth * 0.08, 24, 48);
    final double topPosition = _clamp(screenHeight * 0.05, 20, 60);
    final double rightPosition = _clamp(screenWidth * 0.04, 12, 32);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: topPosition,
              right: rightPosition,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: closeIconSize),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileOptions(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double bottomSheetRadius = _clamp(screenWidth * 0.05, 12, 24);
    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double titleFontSize = _clamp(screenWidth * 0.04, 14, 22);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(bottomSheetRadius)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final userState = ref.watch(userDataProvider);
            final hasImage =
                (userState.userData?['imageUrl']?.toString().isNotEmpty == true) ||
                (userState.imageFile != null);

            return SafeArea(
              child: Wrap(
                children: [
                  if (hasImage)
                    ListTile(
                      leading: Icon(Icons.visibility, color: Colors.black, size: iconSize),
                      title: Text("View Photo", style: TextStyle(fontSize: titleFontSize)),
                      onTap: () {
                        Navigator.pop(context);
                        if (userState.imageFile != null) {
                          _showFullScreenImageFromFile(context, userState.imageFile!);
                        } else {
                          final url = userState.userData!['imageUrl'].toString();
                          _showFullScreenImage(context, url);
                        }
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.photo_library, size: iconSize),
                    title: Text(
                      hasImage ? "Change Photo" : "Choose Photo",
                      style: TextStyle(fontSize: titleFontSize),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(userDataProvider.notifier).pickImage();
                    },
                  ),
                  if (userState.userData?['imageUrl']?.toString().isNotEmpty == true)
                    ListTile(
                      leading: Icon(Icons.delete, color: Colors.red, size: iconSize),
                      title: Text(
                        "Delete Photo",
                        style: TextStyle(color: Colors.red, fontSize: titleFontSize),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.read(userDataProvider.notifier).deleteProfileImage();
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.cancel, size: iconSize),
                    title: Text("Cancel", style: TextStyle(fontSize: titleFontSize)),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _initializeProfile() async {
    await ref.read(userDataProvider.notifier).loadUserIdAndProfile();
    final userState = ref.read(userDataProvider);
    final nameController = ref.read(nameControllerProvider);
    final emailController = ref.read(emailControllerProvider);
    final phoneController = ref.read(phoneControllerProvider);

    if (userState.originalName != null && nameController.text.isEmpty) {
      nameController.text = userState.originalName!;
    }
    if (userState.originalEmail != null && emailController.text.isEmpty) {
      emailController.text = userState.originalEmail!;
    }
    if (userState.originalPhone != null && phoneController.text.isEmpty) {
      phoneController.text = userState.originalPhone!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final topPadding = MediaQuery.of(context).padding.top;

    // Responsive clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double backIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double cardMargin = _clamp(screenWidth * 0.04, 12, 24);
    final double cardPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double cardRadius = _clamp(screenWidth * 0.032, 8, 16);
    final double cardElevation = _clamp(screenWidth * 0.005, 2, 6);
    final double innerPadding = _clamp(screenWidth * 0.02, 6, 16);
    final double sectionTitleSize = _clamp(screenWidth * 0.045, 16, 24);
    final double popupIconSize = _clamp(screenWidth * 0.055, 18, 28);
    final double popupTextSize = _clamp(screenWidth * 0.0375, 12, 18);
    final double saveIconSize = _clamp(screenWidth * 0.05, 16, 24);
    final double saveLabelSize = _clamp(screenWidth * 0.035, 12, 18);
    final double avatarRadius = _clamp(screenWidth * 0.125, 40, 80);
    final double editIconRadius = _clamp(screenWidth * 0.045, 16, 30);
    final double editIconSize = _clamp(screenWidth * 0.045, 16, 28);
    final double textFieldFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double labelFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double textFieldRadius = _clamp(screenWidth * 0.025, 6, 14);
    final double textFieldContentPadH = _clamp(screenWidth * 0.04, 12, 24);
    final double textFieldContentPadV = _clamp(screenHeight * 0.02, 10, 20);
    final double spacingSmall = _clamp(screenHeight * 0.015, 8, 16);
    final double spacingMedium = _clamp(screenHeight * 0.02, 12, 24);
    final double spacingLarge = _clamp(screenHeight * 0.025, 16, 32);
    final double emptyIconSize = _clamp(screenWidth * 0.15, 50, 100);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double buttonFontSize = _clamp(screenWidth * 0.035, 12, 18);

    final userState = ref.watch(userDataProvider);
    final nameController = ref.watch(nameControllerProvider);
    final emailController = ref.watch(emailControllerProvider);
    final phoneController = ref.watch(phoneControllerProvider);

    ref.listen(userDataProvider, (previous, next) {
      if (next.originalName != null && nameController.text.isEmpty) {
        nameController.text = next.originalName!;
      }
      if (next.originalEmail != null && emailController.text.isEmpty) {
        emailController.text = next.originalEmail!;
      }
      if (next.originalPhone != null && phoneController.text.isEmpty) {
        phoneController.text = next.originalPhone!;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: appBarTitleSize,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: backIconSize),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userState.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: loadingStrokeWidth,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(userDataProvider.notifier).loadProfile();
              },
              color: Colors.green,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildProfileSection(
                    userState,
                    nameController,
                    emailController,
                    phoneController,
                    screenWidth,
                    screenHeight,
                    cardMargin,
                    cardPadding,
                    cardRadius,
                    cardElevation,
                    innerPadding,
                    sectionTitleSize,
                    popupIconSize,
                    popupTextSize,
                    saveIconSize,
                    saveLabelSize,
                    avatarRadius,
                    editIconRadius,
                    editIconSize,
                    textFieldFontSize,
                    labelFontSize,
                    textFieldRadius,
                    textFieldContentPadH,
                    textFieldContentPadV,
                    spacingSmall,
                    spacingMedium,
                    spacingLarge,
                    emptyIconSize,
                    emptyTextSize,
                    buttonFontSize,
                    loadingStrokeWidth,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection(
    UserDataState userState,
    TextEditingController nameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    double screenWidth,
    double screenHeight,
    double cardMargin,
    double cardPadding,
    double cardRadius,
    double cardElevation,
    double innerPadding,
    double sectionTitleSize,
    double popupIconSize,
    double popupTextSize,
    double saveIconSize,
    double saveLabelSize,
    double avatarRadius,
    double editIconRadius,
    double editIconSize,
    double textFieldFontSize,
    double labelFontSize,
    double textFieldRadius,
    double textFieldContentPadH,
    double textFieldContentPadV,
    double spacingSmall,
    double spacingMedium,
    double spacingLarge,
    double emptyIconSize,
    double emptyTextSize,
    double buttonFontSize,
    double loadingStrokeWidth,
  ) {
    if (userState.userId == null || userState.userId!.isEmpty) {
      return Card(
        margin: EdgeInsets.all(cardMargin),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            children: [
              Icon(Icons.person_off, size: emptyIconSize, color: Colors.grey),
              SizedBox(height: spacingMedium),
              Text(
                "Please login to view and edit your profile",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: emptyTextSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacingMedium),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Go Back", style: TextStyle(fontSize: buttonFontSize)),
              ),
            ],
          ),
        ),
      );
    }

    if (userState.userData == null) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(cardMargin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      elevation: cardElevation,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Padding(
          padding: EdgeInsets.all(innerPadding),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Profile Info",
                      style: TextStyle(
                        fontSize: sectionTitleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: spacingSmall,
                    runSpacing: spacingSmall,
                    alignment: WrapAlignment.end,
                    children: [
                      if (!userState.isEditing)
                        Container(
                          constraints: BoxConstraints(
                            minWidth: _clamp(screenWidth * 0.1, 40, 80),
                            maxWidth: _clamp(screenWidth * 0.15, 60, 120),
                          ),
                          child: PopupMenuButton<String>(
                            key: const Key('edit_menu_button'),
                            icon: Icon(Icons.more_vert, color: Colors.black, size: popupIconSize),
                            elevation: 2,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(cardRadius),
                            ),
                            offset: Offset(0, _clamp(screenHeight * 0.05, 20, 60)),
                            constraints: BoxConstraints(
                              minWidth: _clamp(screenWidth * 0.25, 80, 160),
                              maxWidth: _clamp(screenWidth * 0.3, 100, 200),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                ref.read(userDataProvider.notifier).enableEditing();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: SizedBox(
                                  width: _clamp(screenWidth * 0.2, 60, 120),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, size: popupIconSize * 0.8, color: Colors.black),
                                      SizedBox(width: spacingSmall),
                                      Text(
                                        'Edit',
                                        style: TextStyle(fontSize: popupTextSize, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (userState.isEditing) ...[
                        TextButton(
                          onPressed: () {
                            nameController.text = userState.originalName!;
                            emailController.text = userState.originalEmail!;
                            phoneController.text = userState.originalPhone!;
                            ref.read(userDataProvider.notifier).cancelEditing();
                          },
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red, fontSize: popupTextSize),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: userState.isSaving
                              ? null
                              : () async {
                                  await ref
                                      .read(userDataProvider.notifier)
                                      .saveProfile(
                                        name: nameController.text,
                                        email: emailController.text,
                                        phone: phoneController.text,
                                        context: context,
                                      );
                                },
                          icon: userState.isSaving
                              ? SizedBox(
                                  width: saveIconSize,
                                  height: saveIconSize,
                                  child: CircularProgressIndicator(
                                    strokeWidth: loadingStrokeWidth,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.save,
                                  size: saveIconSize,
                                  color: Colors.white,
                                ),
                          label: Text(
                            userState.isSaving ? "Saving..." : "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: saveLabelSize,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              horizontal: _clamp(screenWidth * 0.03, 8, 16),
                              vertical: _clamp(screenHeight * 0.015, 6, 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: spacingMedium),
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!userState.isEditing) {
                        ref.read(userDataProvider.notifier).enableEditing();
                      }
                      _showProfileOptions(context, ref);
                    },
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.grey.shade200,
                      child: _buildProfileImage(
                        userState,
                        screenWidth,
                        screenHeight,
                        avatarRadius,
                      ),
                    ),
                  ),
                  if (userState.isEditing)
                    Positioned(
                      bottom: 0,
                      right: _clamp(screenWidth * 0.01, 2, 8),
                      child: CircleAvatar(
                        radius: editIconRadius,
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: editIconSize,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: spacingMedium),
              TextField(
                controller: nameController,
                style: TextStyle(
                  fontSize: textFieldFontSize,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: labelFontSize),
                  prefixIcon: Icon(Icons.person, color: Colors.green, size: _clamp(screenWidth * 0.055, 18, 28)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: userState.isEditing
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: textFieldContentPadH,
                    vertical: textFieldContentPadV,
                  ),
                ),
                enabled: userState.isEditing,
              ),
              SizedBox(height: spacingSmall),
              TextField(
                controller: emailController,
                style: TextStyle(
                  fontSize: textFieldFontSize,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: labelFontSize),
                  prefixIcon: Icon(Icons.email, color: Colors.green, size: _clamp(screenWidth * 0.055, 18, 28)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: userState.isEditing
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: textFieldContentPadH,
                    vertical: textFieldContentPadV,
                  ),
                ),
                enabled: userState.isEditing,
              ),
              SizedBox(height: spacingSmall),
              TextField(
                controller: phoneController,
                style: TextStyle(
                  fontSize: textFieldFontSize,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: labelFontSize),
                  prefixIcon: Icon(Icons.phone, color: Colors.green, size: _clamp(screenWidth * 0.055, 18, 28)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(textFieldRadius),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: userState.isEditing
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: textFieldContentPadH,
                    vertical: textFieldContentPadV,
                  ),
                ),
                keyboardType: TextInputType.phone,
                enabled: userState.isEditing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(
    UserDataState userState,
    double screenWidth,
    double screenHeight,
    double avatarRadius,
  ) {
    final double imageSize = avatarRadius * 2;

    if (userState.userId == null || userState.userId!.isEmpty) {
      return Icon(Icons.person_off, size: avatarRadius * 1.2, color: Colors.grey);
    }

    if (userState.imageFile != null) {
      return ClipOval(
        child: Image.file(
          userState.imageFile!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
        ),
      );
    }

    String? profileImageUrl = userState.userData?['imageUrl']?.toString();

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profileImageUrl,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person, size: avatarRadius * 1.2, color: Colors.grey);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Icon(Icons.person, size: avatarRadius * 1.2, color: Colors.grey);
          },
        ),
      );
    }

    return Icon(Icons.person, size: avatarRadius * 1.2, color: Colors.grey);
  }
}