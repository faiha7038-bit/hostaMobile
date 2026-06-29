// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';

// class UploadDialog extends StatefulWidget {
//   const UploadDialog({super.key});

//   @override
//   State<UploadDialog> createState() => _UploadDialogState();
// }

// class _UploadDialogState extends State<UploadDialog> {
//   File? _selectedFile;
//   String _docType = 'lab';
//   String _fileName = '';
//   String _fileSize = '';
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _doctorNameController = TextEditingController();
//   bool _isUploading = false;

//   Future<void> _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
//         allowMultiple: false,
//       );

//       if (result != null) {
//         final file = File(result.files.single.path!);
//         final sizeInKB = (await file.length() / 1024).toStringAsFixed(1);
        
//         setState(() {
//           _selectedFile = file;
//           _fileName = result.files.single.name;
//           _fileSize = '$sizeInKB KB';
//         });
//       }
//     } catch (e) {
//       _showSnackBar('Error picking file: $e', isError: true);
//     }
//   }

//   Future<void> _pickImage() async {
//     try {
//       final ImagePicker picker = ImagePicker();
//       final XFile? image = await picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//       );

//       if (image != null) {
//         final file = File(image.path);
//         final sizeInKB = (await file.length() / 1024).toStringAsFixed(1);
        
//         setState(() {
//           _selectedFile = file;
//           _fileName = image.name;
//           _fileSize = '$sizeInKB KB';
//         });
//       }
//     } catch (e) {
//       _showSnackBar('Error picking image: $e', isError: true);
//     }
//   }

//   Future<void> _saveDocument() async {
//     if (_selectedFile == null) {
//       _showSnackBar('Please select a file first', isError: true);
//       return;
//     }

//     setState(() => _isUploading = true);

//     try {
//       // Copy file to app directory for persistence
//       final appDir = await getApplicationDocumentsDirectory();
//       final fileName = DateTime.now().millisecondsSinceEpoch.toString() +
//           _selectedFile!.path.substring(_selectedFile!.path.lastIndexOf('.'));
//       final newPath = '${appDir.path}/$fileName';
      
//       await _selectedFile!.copy(newPath);

//       Navigator.pop(context, {
//         'filePath': newPath,
//         'fileName': _fileName,
//         'docType': _docType,
//         'fileSize': _fileSize,
//         'description': _descriptionController.text,
//         'doctorName': _doctorNameController.text,
//       });
//     } catch (e) {
//       _showSnackBar('Error saving document: $e', isError: true);
//       setState(() => _isUploading = false);
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         constraints: const BoxConstraints(maxHeight: 600),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Upload Document',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // File Selection
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Select File',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: _pickFile,
//                         icon: const Icon(Icons.attach_file),
//                         label: const Text('Browse Files'),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     OutlinedButton.icon(
//                       onPressed: _pickImage,
//                       icon: const Icon(Icons.image),
//                       label: const Text('Image'),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (_selectedFile != null) ...[
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.green[50],
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.green[200]!),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.check_circle,
//                             color: Colors.green, size: 20),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 _fileName,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               Text(
//                                 _fileSize,
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
            
//             const SizedBox(height: 16),
            
//             // Document Type
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Document Type',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildTypeChip('Lab Report', 'lab'),
//                     const SizedBox(width: 8),
//                     _buildTypeChip('Prescription', 'prescription'),
//                   ],
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 16),
            
//             // Description
//             TextField(
//               controller: _descriptionController,
//               decoration: const InputDecoration(
//                 hintText: 'Description (optional)',
//                 border: OutlineInputBorder(),
//                 contentPadding: EdgeInsets.symmetric(horizontal: 12),
//               ),
//               maxLines: 2,
//             ),
            
//             const SizedBox(height: 12),
            
//             // Doctor Name
//             TextField(
//               controller: _doctorNameController,
//               decoration: const InputDecoration(
//                 hintText: 'Doctor\'s Name (optional)',
//                 border: OutlineInputBorder(),
//                 contentPadding: EdgeInsets.symmetric(horizontal: 12),
//               ),
//             ),
            
//             const SizedBox(height: 20),
            
//             // Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _isUploading ? null : _saveDocument,
//                   child: _isUploading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Text('Upload'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTypeChip(String label, String value) {
//     return ChoiceChip(
//       label: Text(label),
//       selected: _docType == value,
//       onSelected: (selected) {
//         if (selected) {
//           setState(() => _docType = value);
//         }
//       },
//       selectedColor: Colors.blue[100],
//       backgroundColor: Colors.grey[200],
//       labelStyle: TextStyle(
//         color: _docType == value ? Colors.blue[700] : Colors.grey[700],
//         fontWeight: _docType == value ? FontWeight.bold : FontWeight.normal,
//       ),
//     );
//   }
// }