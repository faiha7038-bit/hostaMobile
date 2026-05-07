import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/profile-provider.dart';

class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  @override
  ConsumerState<Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    await ref.read(userDataProvider.notifier).loadUserIdAndProfile();
    // Sync controllers
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
    
    // Watch the user data state
    final userState = ref.watch(userDataProvider);
    final nameController = ref.watch(nameControllerProvider);
    final emailController = ref.watch(emailControllerProvider);
    final phoneController = ref.watch(phoneControllerProvider);

    // Sync controllers when user data changes
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
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
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
                  ),
                  // _buildDonorSection(),
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
  ) {
    if (userState.userId == null || userState.userId!.isEmpty) {
      return Card(
        margin: EdgeInsets.all(screenWidth * 0.04),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              Icon(Icons.person_off, size: screenWidth * 0.15, color: Colors.grey),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "Please login to view and edit your profile",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Go Back", style: TextStyle(fontSize: screenWidth * 0.035)),
              ),
            ],
          ),
        ),
      );
    }

    if (userState.userData == null) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(screenWidth * 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Profile Info",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: screenWidth * 0.02,
                    runSpacing: screenHeight * 0.005,
                    alignment: WrapAlignment.end,
                    children: [
                      if (!userState.isEditing)
                        Container(
                          constraints: BoxConstraints(
                            minWidth: screenWidth * 0.1,
                            maxWidth: screenWidth * 0.15,
                          ),
                          child: PopupMenuButton<String>(
                            key: const Key('edit_menu_button'),
                            icon: const Icon(Icons.more_vert, color: Colors.black, size: 20),
                            elevation: 2,
                            color: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            offset: Offset(0, screenHeight * 0.05),
                            constraints: BoxConstraints(
                              minWidth: screenWidth * 0.25,
                              maxWidth: screenWidth * 0.3,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                ref.read(userDataProvider.notifier).enableEditing();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, size: 16, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: TextStyle(fontSize: 14, color: Colors.white),
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
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
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
                                  width: screenWidth * 0.04,
                                  height: screenWidth * 0.04,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.save,
                                  size: 18,
                                  color: Colors.white,
                                ),
                          label: Text(
                            userState.isSaving ? "Saving..." : "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),
              Stack(
                children: [
                  GestureDetector(
                    onTap: userState.isEditing
                        ? () async {
                            await ref
                                .read(userDataProvider.notifier)
                                .pickImage();
                          }
                        : null,
                    child: CircleAvatar(
                      radius: screenWidth * 0.125,
                      backgroundColor: Colors.grey.shade200,
                      child: _buildProfileImage(userState, screenWidth, screenHeight),
                    ),
                  ),
                  if (userState.isEditing)
                    Positioned(
                      bottom: 0,
                      right: screenWidth * 0.01,
                      child: CircleAvatar(
                        radius: screenWidth * 0.045,
                        backgroundColor: Colors.green,
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: screenWidth * 0.045,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),
              TextField(
                controller: nameController,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                  prefixIcon: const Icon(Icons.person, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: userState.isEditing
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
                enabled: userState.isEditing,
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                controller: emailController,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                  prefixIcon: const Icon(Icons.email, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: userState.isEditing
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
                enabled: userState.isEditing,
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                controller: phoneController,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                  prefixIcon: const Icon(Icons.phone, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: userState.isEditing
                      ? Colors.grey.shade50
                      : Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
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

  Widget _buildProfileImage(UserDataState userState, double screenWidth, double screenHeight) {
    if (userState.userId == null || userState.userId!.isEmpty) {
      return Icon(Icons.person_off, size: screenWidth * 0.15, color: Colors.grey);
    }

    // Show selected image if available
    if (userState.imageFile != null) {
      return ClipOval(
        child: Image.file(
          userState.imageFile!,
          width: screenWidth * 0.25,
          height: screenWidth * 0.25,
          fit: BoxFit.cover,
        ),
      );
    }

    // Show existing profile image from server
    final pictureData = userState.userData?['picture'];
    String? profileImageUrl;

    if (pictureData is Map<String, dynamic>) {
      profileImageUrl = pictureData['imageUrl']?.toString();
    }

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profileImageUrl,
          width: screenWidth * 0.25,
          height: screenWidth * 0.25,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("❌ Error loading network image: $error");
            return Icon(Icons.person, size: screenWidth * 0.15, color: Colors.grey);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Icon(Icons.person, size: screenWidth * 0.15, color: Colors.grey);
          },
        ),
      );
    }

    // Default avatar
    return Icon(Icons.person, size: screenWidth * 0.15, color: Colors.grey);
  }
}