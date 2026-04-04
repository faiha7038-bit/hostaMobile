import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/donate/donate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ApiService _apiService = ApiService();
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  String? userId;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? donorData;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  File? imageFile;
  String? originalName;
  String? originalEmail;
  String? originalPhone;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndProfile();
  }

  Future<void> _loadUserIdAndProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      
      if (mounted) {
        setState(() {
          userId = storedUserId;
        });
      }
      
      print("📱 Loaded user ID for profile: $userId");
      
      if (userId != null && userId!.isNotEmpty) {
        await _loadProfile();
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
        print("❌ No user ID found for profile");
      }
    } catch (e) {
      print("❌ Error loading user ID: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadProfile() async {
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Always load user data
      final userRes = await _apiService.getAUser(userId!);
      
      // Try to load donor data, but handle 404 gracefully
      dynamic donorRes;
      try {
        donorRes = await _apiService.getADonor(userId!);
        print("✅ Donor data found for user");
      } catch (e) {
        // Check if it's a 404 error (donor not found) - this is normal for non-donors
        if (e.toString().contains('404') || e.toString().contains('Client error')) {
          print("ℹ️ No donor record found for user (this is normal for non-donors)");
          donorRes = null;
        } else {
          // Re-throw if it's a different error
          print("❌ Error loading donor data: $e");
          donorRes = null;
        }
      }

      setState(() {
        userData = userRes.data?['data'] ?? userRes.data ?? {};
        
        // Handle donor data based on the response
        if (donorRes == null) {
          donorData = null; // No donor record exists
        } else if (donorRes.data is List) {
          donorData = donorRes.data.isNotEmpty ? donorRes.data[0] : {};
        } else {
          donorData = donorRes.data ?? {};
        }

        // Set original values
        originalName = (userData?['name'] ?? '').toString();
        originalEmail = (userData?['email'] ?? '').toString();
        originalPhone = (userData?['phone'] ?? '').toString();

        // Set controller values
        nameController.text = originalName!;
        emailController.text = originalEmail!;
        phoneController.text = originalPhone!;
      });

      print("✅ Profile loaded successfully");
      print("🩸 Donor data exists: ${donorData != null}");
      if (donorData != null) {
        print("🩸 Donor data: $donorData");
      }
    } catch (e) {
      print("❌ Error loading profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _enableEditing() {
    setState(() {
      isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      // Reset to original values
      nameController.text = originalName!;
      emailController.text = originalEmail!;
      phoneController.text = originalPhone!;
      imageFile = null;
    });
  }

  Future<void> _saveProfile() async {
    if (userId == null || userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID not found")),
      );
      return;
    }

    if (nameController.text.trim().isEmpty || 
        emailController.text.trim().isEmpty || 
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      setState(() => isSaving = true);
      
      final payload = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
      };
      
      // Use the new method that handles image upload
      await _apiService.updateUserWithImage(userId!, payload, imageFile);
      
      // Update original values
      originalName = nameController.text;
      originalEmail = emailController.text;
      originalPhone = phoneController.text;

      // Reset image file after successful upload
      imageFile = null;

      setState(() {
        isEditing = false;
        isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green,),
      );
      
      // Reload to get updated data
      _loadProfile();
      
    } 
    on DioException catch (dioError) {

  String errorMessage = "Something went wrong";

  if (dioError.response != null) {
    try {
      errorMessage = dioError.response?.data['message'] ?? errorMessage;
    } catch (_) {}
  }


} 
    
    
    
    catch (e) {
      setState(() => isSaving = false);
      print("❌ Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    }
  }

  Future<void> _pickImage() async {
    if (!isEditing) return;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          imageFile = File(pickedFile.path);
        });
        print("📸 Image selected: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Donor Record"),
          content: const Text("Are you sure you want to delete your donor record? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteDonor();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDonor() async {
    try {
      final donorId = donorData?['_id']?.toString();
      if (donorId == null) {
        throw Exception("Donor ID not found");
      }

      await _apiService.deleteDonor(donorId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Donor record deleted successfully"), backgroundColor: Colors.green,),
      );
      
      setState(() => donorData = null);
final prefs = await SharedPreferences.getInstance();
await prefs.remove('bloodId');
      
    } 
     on DioException catch (dioError) {

  String errorMessage = "Something went wrong";

  if (dioError.response != null) {
    try {
      errorMessage = dioError.response?.data['message'] ?? errorMessage;
    } catch (_) {}
  }


} 
    
    catch (e) {
      print("❌ Error deleting donor: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting donor: $e")),
      );
    }
  }

  Widget _buildProfileSection() {
    if (userId == null || userId!.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.person_off, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Please login to view and edit your profile",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    if (userData == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  "Profile Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                if (!isEditing)
                  ElevatedButton.icon(
                    onPressed: _enableEditing,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text("Edit", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                if (isEditing) ...[
                  TextButton(
                    onPressed: _cancelEditing,
                    child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : _saveProfile,
                    icon: isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18, color: Colors.white),
                    label: Text(
                      isSaving ? "Saving..." : "Save", 
                      style: const TextStyle(color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            
            Stack(
              children: [
                GestureDetector(
                  onTap: isEditing ? _pickImage : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    child: _buildProfileImage(),
                  ),
                ),
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: nameController,
              style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: const TextStyle(color: Colors.grey),
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
                fillColor: isEditing ? Colors.grey.shade50 : Colors.grey.shade100,
              ),
              enabled: isEditing,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: emailController,
              style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(color: Colors.grey),
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
                fillColor: isEditing ? Colors.grey.shade50 : Colors.grey.shade100,
              ),
              enabled: isEditing,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: phoneController,
              style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: "Phone Number",
                labelStyle: const TextStyle(color: Colors.grey),
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
                fillColor: isEditing ? Colors.grey.shade50 : Colors.grey.shade100,
              ),
              keyboardType: TextInputType.phone,
              enabled: isEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (userId == null || userId!.isEmpty) {
      return const Icon(Icons.person_off, size: 60, color: Colors.grey);
    }

    // Show selected image if available
    if (imageFile != null) {
      return ClipOval(
        child: Image.file(
          imageFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // Show existing profile image from server
    final pictureData = userData?['picture'];
    String? profileImageUrl;
    
    if (pictureData is Map<String, dynamic>) {
      profileImageUrl = pictureData['imageUrl']?.toString();
    }
    
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profileImageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("❌ Error loading network image: $error");
            return const Icon(Icons.person, size: 60, color: Colors.grey);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Icon(Icons.person, size: 60, color: Colors.grey);
          },
        ),
      );
    }
    
    // Default avatar
    return const Icon(Icons.person, size: 60, color: Colors.grey);
  }

  Widget _buildDonorSection() {
    if (userId == null || userId!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if donor data exists and has meaningful content
    if (donorData == null) {
      return _buildNoDonorSection();
    }

    // Check if donor data is empty or doesn't contain meaningful information
    if (donorData!.isEmpty) {
      return _buildNoDonorSection();
    }

    final address = donorData?['address'] ?? {};
    
    final hasBloodGroup = donorData?['bloodGroup'] != null && 
                         donorData!['bloodGroup'].toString().isNotEmpty;
    
    final hasAddressData = address.isNotEmpty && 
        ((address['country'] != null && address['country']!.toString().isNotEmpty) || 
         (address['state'] != null && address['state']!.toString().isNotEmpty) || 
         (address['district'] != null && address['district']!.toString().isNotEmpty));

    if (!hasBloodGroup && !hasAddressData) {
      return _buildNoDonorSection();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Blood Donation Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showDeleteConfirmation,
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                  tooltip: "Delete donor record",
                ),
              ],
            ),
            const Divider(),
            
            if (hasBloodGroup)
              _buildDonorDetail("Blood Group", _safeToString(donorData?['bloodGroup'])),
            
            if (donorData?['dateOfBirth'] != null && donorData!['dateOfBirth'].toString().isNotEmpty)
              _buildDonorDetail(
                "Date of Birth", 
                _safeToString(donorData?['dateOfBirth'])?.split('T').first ?? '-'
              ),
            
            if (hasAddressData) ...[
              const SizedBox(height: 8),
              const Text(
                "Address:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              
              if (address['country'] != null && address['country']!.toString().isNotEmpty)
                _buildDonorDetail("Country", _safeToString(address['country'])),
              
              if (address['state'] != null && address['state']!.toString().isNotEmpty)
                _buildDonorDetail("State", _safeToString(address['state'])),
              
              if (address['district'] != null && address['district']!.toString().isNotEmpty)
                _buildDonorDetail("District", _safeToString(address['district'])),
              
              if (address['place'] != null && address['place']!.toString().isNotEmpty)
                _buildDonorDetail("Place", _safeToString(address['place'])),
              
              if (address['pincode'] != null && address['pincode']!.toString().isNotEmpty)
                _buildDonorDetail("Pincode", _safeToString(address['pincode'])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoDonorSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.bloodtype_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              "No Donor Profile Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You haven't registered as a blood donor yet.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to donor registration page
                Navigator.push(context, MaterialPageRoute(builder: (context) => Donate()));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Register as Donor"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorDetail(String label, String? value) {
    final displayValue = value ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label: ",
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  String? _safeToString(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  @override
  Widget build(BuildContext context) {
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: Colors.green,
              child: ListView(
                children: [
                  _buildProfileSection(),
                  _buildDonorSection(),
                ],
              ),
            ),
    );
  }
}