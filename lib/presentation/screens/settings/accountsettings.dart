

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
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          title: Text(
            "Delete Account",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: isSmallScreen 
                  ? screenWidth * 0.05 
                  : isMediumScreen 
                      ? screenWidth * 0.04 
                      : screenWidth * 0.03,
            ),
          ),
          content: Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.04 
                  : isMediumScreen 
                      ? screenWidth * 0.032 
                      : screenWidth * 0.025,
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
                  fontSize: isSmallScreen 
                      ? screenWidth * 0.04 
                      : isMediumScreen 
                          ? screenWidth * 0.032 
                          : screenWidth * 0.025,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              child: Text(
                "Delete",
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Account deleted successfully',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.015,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(screenWidth * 0.02),
          ),
        ),
      ),
    );
  }

  void _showErrorMessage() {
    final errorMessage = ref.read(accountStateProvider).errorMessage;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errorMessage ?? 'Failed to delete account. Please try again.',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.015,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(screenWidth * 0.02),
          ),
        ),
      ),
    );
  }

  void _navigateToBottomNav() {
    ref.read(accountStateProvider.notifier).reset();
    
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
    
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios, 
            color: Colors.white, 
            size: isSmallScreen 
                ? screenWidth * 0.055 
                : isMediumScreen 
                    ? screenWidth * 0.04 
                    : screenWidth * 0.03,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isSmallScreen 
                ? screenWidth * 0.05 
                : isMediumScreen 
                    ? screenWidth * 0.04 
                    : screenWidth * 0.028,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
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
            ? _buildLargeScreenLayout(screenWidth, screenHeight, isDeleting)
            : _buildSmallMediumScreenLayout(screenWidth, screenHeight, isDeleting),
      ),
    );
  }

  Widget _buildSmallMediumScreenLayout(
    double screenWidth, 
    double screenHeight, 
    bool isDeleting
  ) {
    final isSmallScreen = screenWidth < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWarningContainer(screenWidth, screenHeight),
        
        SizedBox(height: screenHeight * 0.05),
        
        _buildDeleteSection(screenWidth, screenHeight, isDeleting),
        
        const Spacer(),
        
        _buildFooterNote(screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildLargeScreenLayout(
    double screenWidth, 
    double screenHeight, 
    bool isDeleting
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildWarningContainer(screenWidth, screenHeight),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDeleteSection(screenWidth, screenHeight, isDeleting),
              SizedBox(height: screenHeight * 0.03),
              _buildFooterNote(screenWidth, screenHeight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningContainer(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isSmallScreen 
            ? screenWidth * 0.04 
            : screenWidth * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: Colors.orange, 
          width: screenWidth * 0.0025,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: screenWidth * 0.02,
            spreadRadius: screenWidth * 0.005,
            offset: Offset(0, screenHeight * 0.005),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: isSmallScreen 
                ? screenWidth * 0.06 
                : screenWidth * 0.05,
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Important Notice',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen 
                  ? screenWidth * 0.04 
                  : screenWidth * 0.035,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            'If you delete your account, it will be temporarily deleted. You can register again with the same email address later if you wish to rejoin.',
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.035 
                  : screenWidth * 0.028,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSection(
    double screenWidth, 
    double screenHeight, 
    bool isDeleting
  ) {
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.delete_forever,
            color: Colors.red[300],
            size: isSmallScreen 
                ? screenWidth * 0.12 
                : isMediumScreen 
                    ? screenWidth * 0.08 
                    : screenWidth * 0.06,
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            'Delete Your Account',
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.045 
                  : isMediumScreen 
                      ? screenWidth * 0.035 
                      : screenWidth * 0.028,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Text(
              'This action will remove all your data and cannot be undone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen 
                    ? screenWidth * 0.035 
                    : isMediumScreen 
                        ? screenWidth * 0.028 
                        : screenWidth * 0.022,
                color: Colors.black,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
          
          if (isDeleting)
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: Colors.red,
                    strokeWidth: isSmallScreen 
                        ? screenWidth * 0.008 
                        : screenWidth * 0.006,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Text(
                    'Deleting your account...',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: _showDeleteConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen 
                      ? screenWidth * 0.08 
                      : screenWidth * 0.06,
                  vertical: isSmallScreen 
                      ? screenHeight * 0.015 
                      : screenHeight * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                elevation: isSmallScreen ? 4 : 6,
                shadowColor: Colors.red.withOpacity(0.3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline, 
                    size: isSmallScreen 
                        ? screenWidth * 0.05 
                        : screenWidth * 0.04,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: isSmallScreen 
                          ? screenWidth * 0.04 
                          : screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterNote(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isSmallScreen 
            ? screenWidth * 0.03 
            : screenWidth * 0.025,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: Colors.grey[200]!,
          width: screenWidth * 0.001,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[600],
            size: isSmallScreen 
                ? screenWidth * 0.04 
                : screenWidth * 0.035,
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Text(
              'Note: After account deletion, you will be logged out and redirected to the login screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen 
                    ? screenWidth * 0.03 
                    : screenWidth * 0.025,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
