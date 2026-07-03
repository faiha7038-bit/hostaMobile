import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/account_stng_provider.dart';
import '../../../presentation/widgets/bottomnav.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  void _showDeleteConfirmationDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Delete Account",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: screenWidth * 0.05,
            ),
          ),
          content: Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _deleteAccount();
              },
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final success = await ref.read(accountStateProvider.notifier).deleteAccount(context);
    
    if (!mounted) return;
    
    if (success) {
      _showSuccessMessage();
      _navigateToBottomNav();
    } else {
      _showErrorMessage();
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ' Your Account has been Blacklisted ',
          style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage() {
    final errorMessage = ref.read(accountStateProvider).errorMessage;
    final screenWidth = MediaQuery.of(context).size.width;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage ?? 'Failed to delete account. Please try again.',
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToBottomNav() {
    // Reset state before navigation
    ref.read(accountStateProvider.notifier).reset();
    
    // Navigate to BottomNav page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Bottomnav()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final accountState = ref.watch(accountStateProvider);
    final isDeleting = accountState.isDeleting;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: screenWidth * 0.055),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message at the top
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: Colors.orange, width: screenWidth * 0.0025),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: screenWidth * 0.06,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Important Notice',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    'Your account has been blacklisted. You can rejoin within 30 days. If you do not rejoin within this period, your account will be permanently deleted.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: screenHeight * 0.05),
            
            // Delete account section
            Center(
              child: Column(
                children: [
                  Text(
                    'Delete Your Account',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'This action will remove all your data and cannot be undone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  
                  if (isDeleting)
                    CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: screenWidth * 0.008,
                    )
                  else
                    ElevatedButton(
                      onPressed: _showDeleteConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: screenWidth * 0.05),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Additional info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Text(
                'Note: After account deletion, you will be logged out and redirected to the login screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}