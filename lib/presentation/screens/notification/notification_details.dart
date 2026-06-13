import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> notification;
  
  const NotificationDetailsScreen({super.key, required this.notification});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Notification Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green[100],
                    child: Icon(
                      Icons.notifications_active,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Message
                Text(
                  "Message",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  notification['message'] ?? "No message",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                // Divider
                Divider(),
                SizedBox(height: 10),
                
                // Time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 10),
                    Text(
                      _formatDateTime(notification['createdAt']),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                
                // Status
                Row(
                  children: [
                    Icon(
                      notification['read'] == true 
                        ? Icons.done_all 
                        : Icons.circle,
                      size: 20,
                      color: notification['read'] == true 
                        ? Colors.green 
                        : Colors.orange,
                    ),
                    SizedBox(width: 10),
                    Text(
                      notification['read'] == true ? "Read" : "Unread",
                      style: TextStyle(
                        color: notification['read'] == true 
                          ? Colors.green 
                          : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                
                // ID
                Row(
                  children: [
                    Icon(Icons.tag, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 10),
                    Text(
                      "ID: ${notification['id']}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
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
}