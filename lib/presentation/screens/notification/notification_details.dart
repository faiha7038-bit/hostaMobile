// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class NotificationDetailsScreen extends StatelessWidget {
//   final Map<String, dynamic> notification;
  
//   const NotificationDetailsScreen({super.key, required this.notification});
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFECFDF5),
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: Text(
//           "Notification Details",
//           style: TextStyle(color: Colors.white),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Icon
//                 Center(
//                   child: CircleAvatar(
//                     radius: 40,
//                     backgroundColor: Colors.green[100],
//                     child: Icon(
//                       Icons.notifications_active,
//                       size: 40,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
                
//                 // Message
//                 Text(
//                   "Message",
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   notification['message'] ?? "No message",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 20),
                
//                 // Divider
//                 Divider(),
//                 SizedBox(height: 10),
                
//                 // Time
//                 Row(
//                   children: [
//                     Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
//                     SizedBox(width: 10),
//                     Text(
//                       _formatDateTime(notification['createdAt']),
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10),
                
//                 // Status
//                 Row(
//                   children: [
//                     Icon(
//                       notification['read'] == true 
//                         ? Icons.done_all 
//                         : Icons.circle,
//                       size: 20,
//                       color: notification['read'] == true 
//                         ? Colors.green 
//                         : Colors.orange,
//                     ),
//                     SizedBox(width: 10),
//                     Text(
//                       notification['read'] == true ? "Read" : "Unread",
//                       style: TextStyle(
//                         color: notification['read'] == true 
//                           ? Colors.green 
//                           : Colors.orange,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10),
                
//                 // ID
//                 Row(
//                   children: [
//                     Icon(Icons.tag, size: 20, color: Colors.grey[600]),
//                     SizedBox(width: 10),
//                     Text(
//                       "ID: ${notification['id']}",
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
  
//   String _formatDateTime(String dateTimeString) {
//     try {
//       final dateTime = DateTime.parse(dateTimeString);
//       final now = DateTime.now();
//       final difference = now.difference(dateTime);
      
//       if (difference.inDays > 0) {
//         return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
//       } else {
//         return DateFormat('hh:mm a').format(dateTime);
//       }
//     } catch (e) {
//       return dateTimeString;
//     }
//   }
// }



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> notification;
  
  const NotificationDetailsScreen({super.key, required this.notification});
  
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
      } else {
        return DateFormat('hh:mm a').format(dateTime);
      }
    } catch (e) {
      return dateTimeString;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    final horizontalPadding = isDesktop 
        ? screenWidth * 0.15 
        : (isTablet ? screenWidth * 0.08 : screenWidth * 0.04);
    final cardPadding = isSmallScreen 
        ? screenWidth * 0.04 
        : screenWidth * 0.05;
    final cardInnerPadding = isSmallScreen 
        ? screenWidth * 0.05 
        : screenWidth * 0.04;
    
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Notification Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen 
                ? screenWidth * 0.05 
                : (isTablet ? screenWidth * 0.04 : screenWidth * 0.028),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: Colors.white,
            size: isSmallScreen 
                ? screenWidth * 0.055 
                : (isTablet ? screenWidth * 0.04 : screenWidth * 0.03),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: isSmallScreen 
            ? kToolbarHeight 
            : (isTablet 
                ? kToolbarHeight * 1.1 
                : kToolbarHeight * 1.2),
        elevation: isSmallScreen ? 0 : 2,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? screenWidth * 0.7 : screenWidth,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: screenHeight * 0.02,
            ),
            child: Card(
              elevation: isSmallScreen ? 4 : 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  isSmallScreen 
                      ? screenWidth * 0.04 
                      : screenWidth * 0.03,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardInnerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        width: isSmallScreen 
                            ? screenWidth * 0.2 
                            : screenWidth * 0.1,
                        height: isSmallScreen 
                            ? screenWidth * 0.2 
                            : screenWidth * 0.1,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          size: isSmallScreen 
                              ? screenWidth * 0.1 
                              : screenWidth * 0.06,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    
                    // Message Label
                    Text(
                      "Message",
                      style: TextStyle(
                        fontSize: isSmallScreen 
                            ? screenWidth * 0.035 
                            : screenWidth * 0.028,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    
                    // Message Content
                    Container(
                      padding: EdgeInsets.all(
                        isSmallScreen 
                            ? screenWidth * 0.03 
                            : screenWidth * 0.025,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(
                          isSmallScreen 
                              ? screenWidth * 0.03 
                              : screenWidth * 0.025,
                        ),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                          width: screenWidth * 0.0025,
                        ),
                      ),
                      child: Text(
                        notification['message'] ?? "No message",
                        style: TextStyle(
                          fontSize: isSmallScreen 
                              ? screenWidth * 0.045 
                              : screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    
                    // Divider
                    Divider(
                      thickness: screenWidth * 0.0025,
                      color: Colors.grey[200],
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    
                    // Time
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: _formatDateTime(notification['createdAt']),
                      iconColor: Colors.grey[600]!,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: screenHeight * 0.0125),
                    
                    // Status
                    _buildInfoRow(
                      icon: notification['read'] == true 
                          ? Icons.done_all 
                          : Icons.circle,
                      label: notification['read'] == true ? "Read" : "Unread",
                      iconColor: notification['read'] == true 
                          ? Colors.green 
                          : Colors.orange,
                      textColor: notification['read'] == true 
                          ? Colors.green 
                          : Colors.orange,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: screenHeight * 0.0125),
                    
                    // ID
                    _buildInfoRow(
                      icon: Icons.tag,
                      label: "ID: ${notification['id']}",
                      iconColor: Colors.grey[600]!,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isSmallScreen: isSmallScreen,
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Action Buttons (Optional - for better UX)
                    if (isDesktop)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                            ),
                            child: Text(
                              "Close",
                              style: TextStyle(
                                fontSize: screenWidth * 0.02,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.02,
                                ),
                              ),
                            ),
                            child: Text(
                              "OK",
                              style: TextStyle(
                                fontSize: screenWidth * 0.02,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required Color iconColor,
    required double screenWidth,
    required double screenHeight,
    required bool isSmallScreen,
    Color? textColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            isSmallScreen 
                ? screenWidth * 0.025 
                : screenWidth * 0.02,
          ),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isSmallScreen 
                ? screenWidth * 0.05 
                : screenWidth * 0.04,
            color: iconColor,
          ),
        ),
        SizedBox(width: screenWidth * 0.025),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.035 
                  : screenWidth * 0.028,
              color: textColor ?? Colors.grey[600],
              fontWeight: textColor != null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}