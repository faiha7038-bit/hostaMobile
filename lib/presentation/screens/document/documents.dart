// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hosta/data/models/document_model.dart';
// import 'package:hosta/providers/document_provider.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// class DocumentsTab extends ConsumerStatefulWidget {
//   const DocumentsTab({Key? key}) : super(key: key);

//   @override
//   _DocumentsTabState createState() => _DocumentsTabState();
// }

// class _DocumentsTabState extends ConsumerState<DocumentsTab> {
//   static const String s3BaseUrl =
//       "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       ref.read(documentProvider.notifier).init();
//     });
//   }

//   String getS3Url(String? key) {
//     if (key == null || key.isEmpty) return '';
//     const base = "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";
//     if (key.startsWith('http')) return key;
//     return base + (key.startsWith('/') ? key.substring(1) : key);
//   }

//   Future<void> _fetchDocuments() async {
//     await ref.read(documentProvider.notifier).refresh();
//   }

//   bool _isImage(Document doc) {
//     final type = doc.fileType ?? doc.type ?? '';
//     if (type.startsWith('image/')) return true;

//     final fileName = doc.fileName ?? '';
//     const imageExts = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
//     if (imageExts.any((ext) => fileName.toLowerCase().endsWith(ext))) return true;

//     final url = doc.imageUrl ?? '';
//     if (url.isNotEmpty) {
//       final lower = url.toLowerCase();
//       if (imageExts.any((ext) => lower.endsWith(ext))) return true;
//     }
//     return false;
//   }

//   bool _isPDF(Document doc) {
//     final type = (doc.fileType ?? doc.type ?? '').toLowerCase();
//     final fileName = (doc.fileName ?? '').toLowerCase();
//     final url = (doc.imageUrl ?? '').toLowerCase();

//     return type.contains('pdf') ||
//         fileName.endsWith('.pdf') ||
//         url.endsWith('.pdf');
//   }

//   Icon _getFileIcon(Document doc) {
//     if (_isImage(doc)) {
//       return const Icon(Icons.image, color: Colors.green, size: 20);
//     } else if (_isPDF(doc)) {
//       return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20);
//     } else {
//       return const Icon(Icons.insert_drive_file, color: Colors.blue, size: 20);
//     }
//   }

//   Color _getFileColor(Document doc) {
//     if (_isImage(doc)) return Colors.green.shade50;
//     if (_isPDF(doc)) return Colors.red.shade50;
//     return Colors.blue.shade50;
//   }

//   void _showToast(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   // ==================== UPLOAD MODAL ====================
//   void _openUploadModal() {
//     final TextEditingController nameController = TextEditingController();
//     String selectedDate = '';
//     File? selectedFile;
//     bool isLoading = false;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             final size = MediaQuery.of(context).size;
//             final isTablet = size.width > 600;

//             return Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Container(
//                 width: isTablet ? size.width * 0.5 : size.width * 0.9,
//                 constraints: BoxConstraints(
//                   maxHeight: size.height * 0.85,
//                 ),
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.only(
//                     left: 24,
//                     right: 24,
//                     top: 24,
//                     bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: Colors.green.shade50,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Icon(
//                               Icons.upload_file,
//                               color: Colors.green.shade700,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'Upload Document',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.grey.shade800,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),

//                       /// Name Field
//                       TextField(
//                         controller: nameController,
//                         decoration: InputDecoration(
//                           labelText: 'Document Name',
//                           hintText: 'Enter document name',
//                           prefixIcon: const Icon(Icons.description),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onChanged: (_) => setModalState(() {}),
//                       ),

//                       const SizedBox(height: 16),

//                       /// Date Picker
//                       GestureDetector(
//                         onTap: () async {
//                           final date = await showDatePicker(
//                             context: context,
//                             firstDate: DateTime(2000),
//                             lastDate: DateTime.now(),
//                             initialDate: DateTime.now(),
//                           );

//                           if (date != null) {
//                             setModalState(() {
//                               selectedDate =
//                                   DateFormat('yyyy-MM-dd').format(date);
//                             });
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.calendar_today),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   selectedDate.isEmpty
//                                       ? 'Select Date'
//                                       : selectedDate,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       /// File Picker
//                       GestureDetector(
//                         onTap: () async {
//                           final result = await FilePicker.platform.pickFiles(
//                             type: FileType.custom,
//                             allowedExtensions: [
//                               'png',
//                               'jpg',
//                               'jpeg',
//                               'webp',
//                               'pdf'
//                             ],
//                           );

//                           if (result != null) {
//                             final file = File(result.files.single.path!);
//                             final size = await file.length();

//                             if (size > 10 * 1024 * 1024) {
//                               _showToast(
//                                 'File size must be < 10MB',
//                                 isError: true,
//                               );
//                               return;
//                             }

//                             setModalState(() {
//                               selectedFile = file;
//                             });

//                             ref.read(documentProvider.notifier).setFile(file);
//                           }
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(
//                                 selectedFile != null
//                                     ? Icons.check_circle
//                                     : Icons.cloud_upload,
//                                 size: 40,
//                                 color: selectedFile != null
//                                     ? Colors.green
//                                     : Colors.grey,
//                               ),
//                               const SizedBox(height: 8),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: Text(
//                                   selectedFile != null
//                                       ? selectedFile!.path.split('/').last
//                                       : 'Tap to select Image or PDF',
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Allowed: PNG, JPG, JPEG, WEBP, PDF',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey.shade500,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       /// Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextButton(
//                               onPressed: isLoading
//                                   ? null
//                                   : () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed: (nameController.text.isEmpty ||
//                                       selectedDate.isEmpty ||
//                                       selectedFile == null ||
//                                       isLoading)
//                                   ? null
//                                   : () async {
//                                       setModalState(() {
//                                         isLoading = true;
//                                       });

//                                       try {
//                                         final patientId = ref
//                                             .read(documentProvider)
//                                             .currentPatientId;

//                                         if (patientId == null) {
//                                           _showToast(
//                                             'Please ensure consultation is completed before uploading',
//                                             isError: true,
//                                           );
//                                           setModalState(() {
//                                             isLoading = false;
//                                           });
//                                           return;
//                                         }

//                                         // Step 1: Create document metadata
//                                         final docId = await ref
//                                             .read(documentProvider.notifier)
//                                             .createDocument(
//                                               name: nameController.text.trim(),
//                                               date: selectedDate,
//                                               patientId: patientId,
//                                             );

//                                         if (docId == null) {
//                                           throw Exception(
//                                               'Failed to create document');
//                                         }

//                                         // Step 2: Upload file for the document
//                                         await ref
//                                             .read(documentProvider.notifier)
//                                             .uploadFileForDocument(
//                                               docId: docId,
//                                               file: selectedFile!,
//                                             );

//                                         if (mounted) {
//                                           _showToast(
//                                               'Document uploaded successfully!');
//                                           Navigator.pop(context);
//                                           await _fetchDocuments();
//                                         }
//                                       } catch (e) {
//                                         if (mounted) {
//                                           _showToast(
//                                             'Failed to upload document: ${e.toString()}',
//                                             isError: true,
//                                           );
//                                         }
//                                         setModalState(() {
//                                           isLoading = false;
//                                         });
//                                       }
//                                     },
//                               child: isLoading
//                                   ? const SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : const Text('Upload'),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // ==================== EDIT MODAL ====================
//   void _openEditModal(Document doc) {
//     final TextEditingController nameController =
//         TextEditingController(text: doc.name);
//     String selectedDate = doc.date;
//     File? editFile;
//     bool isLoading = false;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             final size = MediaQuery.of(context).size;
//             final isTablet = size.width > 600;

//             return Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Container(
//                 width: isTablet ? size.width * 0.5 : size.width * 0.9,
//                 constraints: BoxConstraints(
//                   maxHeight: size.height * 0.85,
//                 ),
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.only(
//                     left: 24,
//                     right: 24,
//                     top: 24,
//                     bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade50,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Icon(
//                               Icons.edit,
//                               color: Colors.blue.shade700,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'Edit Document',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.grey.shade800,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),

//                       TextField(
//                         controller: nameController,
//                         decoration: InputDecoration(
//                           labelText: 'Document Name',
//                           hintText: 'Enter document name',
//                           prefixIcon: const Icon(Icons.description),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onChanged: (_) => setModalState(() {}),
//                       ),

//                       const SizedBox(height: 16),

//                       GestureDetector(
//                         onTap: () async {
//                           final date = await showDatePicker(
//                             context: context,
//                             initialDate: selectedDate.isNotEmpty
//                                 ? DateTime.parse(selectedDate)
//                                 : DateTime.now(),
//                             firstDate: DateTime(2000),
//                             lastDate: DateTime.now(),
//                           );

//                           if (date != null) {
//                             setModalState(() {
//                               selectedDate =
//                                   DateFormat('yyyy-MM-dd').format(date);
//                             });
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.calendar_today),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   selectedDate.isEmpty
//                                       ? 'Select Date'
//                                       : selectedDate,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       GestureDetector(
//                         onTap: () async {
//                           final result = await FilePicker.platform.pickFiles(
//                             type: FileType.custom,
//                             allowedExtensions: [
//                               'png',
//                               'jpg',
//                               'jpeg',
//                               'webp',
//                               'pdf'
//                             ],
//                           );

//                           if (result != null) {
//                             final file = File(result.files.single.path!);
//                             final size = await file.length();

//                             if (size > 10 * 1024 * 1024) {
//                               _showToast(
//                                 'File size must be < 10MB',
//                                 isError: true,
//                               );
//                               return;
//                             }

//                             setModalState(() {
//                               editFile = file;
//                             });

//                             ref.read(documentProvider.notifier).setFile(file);
//                           }
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(
//                                 editFile != null
//                                     ? Icons.check_circle
//                                     : Icons.cloud_upload,
//                                 size: 40,
//                                 color: editFile != null
//                                     ? Colors.green
//                                     : Colors.grey,
//                               ),
//                               const SizedBox(height: 8),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: Text(
//                                   editFile != null
//                                       ? editFile!.path.split('/').last
//                                       : 'Tap to select a new file (optional)',
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Allowed: PNG, JPG, JPEG, WEBP, PDF',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey.shade500,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextButton(
//                               onPressed: isLoading
//                                   ? null
//                                   : () => Navigator.pop(context),
//                               child: const Text('Cancel'),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: ElevatedButton(
//                               onPressed: (nameController.text.isEmpty ||
//                                       selectedDate.isEmpty ||
//                                       isLoading)
//                                   ? null
//                                   : () async {
//                                       setModalState(() {
//                                         isLoading = true;
//                                       });

//                                       try {
//                                         // Update document metadata
//                                         await ref
//                                             .read(documentProvider.notifier)
//                                             .updateDocument(
//                                               docId: doc.id.toString(),
//                                               name: nameController.text.trim(),
//                                               date: selectedDate,
//                                             );

//                                         // If a new file was selected, upload it
//                                         if (editFile != null) {
//                                           await ref
//                                               .read(documentProvider.notifier)
//                                               .uploadFileForDocument(
//                                                 docId: int.parse(
//                                                     doc.id.toString()),
//                                                 file: editFile!,
//                                               );
//                                         }

//                                         if (mounted) {
//                                           _showToast(
//                                               'Document updated successfully!');
//                                           Navigator.pop(context);
//                                           await _fetchDocuments();
//                                         }
//                                       } catch (e) {
//                                         if (mounted) {
//                                           _showToast(
//                                             'Failed to update document: ${e.toString()}',
//                                             isError: true,
//                                           );
//                                         }
//                                         setModalState(() {
//                                           isLoading = false;
//                                         });
//                                       }
//                                     },
//                               child: isLoading
//                                   ? const SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : const Text('Update'),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // ==================== DOCUMENT CARD ====================
//   Widget _buildDocumentCard(Document doc, VoidCallback onTap) {
//     final hasFile = doc.imageUrl != null && doc.imageUrl!.isNotEmpty;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: Colors.grey.shade200),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: hasFile ? onTap : null,
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   color: _getFileColor(doc),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: _getFileIcon(doc),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       doc.name,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       softWrap: false,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       doc.date.isNotEmpty
//                           ? DateFormat('yyyy-MM-dd')
//                               .format(DateTime.parse(doc.date))
//                           : 'N/A',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               PopupMenuButton<String>(
//                 icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
//                 onSelected: (value) {
//                   switch (value) {
//                     case 'view':
//                       if (hasFile) onTap();
//                       break;
//                     case 'edit':
//                       _openEditModal(doc);
//                       break;
//                     case 'delete':
//                       _handleDelete(doc);
//                       break;
//                   }
//                 },
//                 itemBuilder: (context) => [
//                   PopupMenuItem(
//                     value: 'view',
//                     enabled: hasFile,
//                     child: Row(
//                       children: [
//                         Icon(Icons.visibility,
//                             size: 18, color: hasFile ? null : Colors.grey),
//                         const SizedBox(width: 8),
//                         Text('View',
//                             style: TextStyle(
//                                 color: hasFile ? null : Colors.grey)),
//                       ],
//                     ),
//                   ),
//                   const PopupMenuItem(
//                     value: 'edit',
//                     child: Row(
//                       children: [
//                         Icon(Icons.edit, size: 18, color: Colors.blue),
//                         SizedBox(width: 8),
//                         Text('Edit'),
//                       ],
//                     ),
//                   ),
//                   const PopupMenuItem(
//                     value: 'delete',
//                     child: Row(
//                       children: [
//                         Icon(Icons.delete_outline,
//                             size: 18, color: Colors.red),
//                         SizedBox(width: 8),
//                         Text('Delete', style: TextStyle(color: Colors.red)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ==================== DELETE ====================
//   Future<void> _handleDelete(Document doc) async {
//     if (doc.id == null) return;

//     final confirm = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(Icons.delete_outline, color: Colors.red.shade700),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 'Delete Document',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           'Are you sure you want to delete "${doc.name}"?',
//           overflow: TextOverflow.ellipsis,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       await ref.read(documentProvider.notifier).deleteDocument(
//             id: int.parse(doc.id.toString()),
//           );
//       if (mounted) {
//         _showToast('Document deleted successfully');
//         await _fetchDocuments();
//       }
//     } catch (e) {
//       if (mounted) {
//         _showToast('Failed to delete document', isError: true);
//       }
//     }
//   }

//   void _openViewModal(Document doc) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (ctx) => _buildViewModal(doc),
//     );
//   }

//   Widget _buildViewModal(Document doc) {
//     final fileUrl = getS3Url(doc.imageUrl);
//     final isPdf = _isPDF(doc);
//     final isImg = _isImage(doc);

//     return Dialog(
//       insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.95,
//         height: MediaQuery.of(context).size.height * 0.9,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: _getFileColor(doc),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: _getFileIcon(doc),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         doc.name,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         doc.date.isNotEmpty
//                             ? DateFormat.yMMMd()
//                                 .format(DateTime.parse(doc.date))
//                             : 'N/A',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey.shade600,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             const Divider(height: 16),
//             Expanded(
//               child: fileUrl.isEmpty
//                   ? const Center(child: Text('No file attached'))
//                   : isPdf
//                       ? SfPdfViewer.network(
//                           fileUrl,
//                           canShowScrollStatus: true,
//                           canShowPaginationDialog: true,
//                         )
//                       : isImg
//                           ? InteractiveViewer(
//                               minScale: 0.5,
//                               maxScale: 4.0,
//                               child: Image.network(
//                                 fileUrl,
//                                 fit: BoxFit.contain,
//                                 errorBuilder: (_, __, ___) => const Center(
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.broken_image,
//                                           size: 64, color: Colors.grey),
//                                       SizedBox(height: 8),
//                                       Text('Unable to load image'),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             )
//                           : Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.insert_drive_file,
//                                       size: 80, color: Colors.blue.shade300),
//                                   const SizedBox(height: 16),
//                                   Text(
//                                     doc.fileName ?? 'Document',
//                                     style: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w500),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton.icon(
//                                     onPressed: () => _launchURL(fileUrl),
//                                     icon: const Icon(Icons.open_in_new),
//                                     label: const Text('Open Document'),
//                                     style: ElevatedButton.styleFrom(
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius:
//                                             BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 if (fileUrl.isNotEmpty && !isPdf)
//                   TextButton.icon(
//                     onPressed: () => _launchURL(fileUrl),
//                     icon: const Icon(Icons.open_in_new, size: 18),
//                     label: const Text('Open in Browser'),
//                     style: TextButton.styleFrom(
//                       foregroundColor: Colors.blue,
//                     ),
//                   ),
//                 const SizedBox(width: 8),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Close'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _launchURL(String url) async {
//     final Uri uri = Uri.parse(url);
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(
//           uri,
//           mode: LaunchMode.externalApplication,
//         );
//       } else {
//         _showToast('Cannot open link', isError: true);
//       }
//     } catch (e) {
//       _showToast('Error: $e', isError: true);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final documents =
//         ref.watch(documentProvider.select((state) => state.documents));
//     final isLoading =
//         ref.watch(documentProvider.select((state) => state.isLoading));
//     final error = ref.watch(documentProvider.select((state) => state.error));

//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text(
//           "My Documents",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.green,
//         centerTitle: true,
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//         ),
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.shade200,
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade50,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(Icons.folder, color: Colors.green.shade700),
//                     ),
//                     const SizedBox(width: 12),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Total Documents',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                         Text(
//                           '${documents.length} files',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                             color: Colors.grey.shade800,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     final patientId =
//                         ref.read(documentProvider).currentPatientId;

//                     if (patientId == null) {
//                       _showToast(
//                         'Only patients who have completed consultation can upload documents.',
//                         isError: true,
//                       );
//                       return;
//                     }
//                     _openUploadModal();
//                   },
//                   icon: const Icon(Icons.upload_file, size: 18),
//                   label: const Text("Upload"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 10),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Builder(
//               builder: (context) {
//                 if (isLoading) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(color: Colors.green),
//                         SizedBox(height: 16),
//                         Text('Loading documents...',
//                             style: TextStyle(color: Colors.grey)),
//                       ],
//                     ),
//                   );
//                 }

//                 if (error != null) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.error_outline,
//                             size: 64, color: Colors.grey.shade400),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Error loading documents',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade700,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           error,
//                           style: TextStyle(color: Colors.grey.shade500),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton.icon(
//                           onPressed: _fetchDocuments,
//                           icon: const Icon(Icons.refresh),
//                           label: const Text('Retry'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 if (documents.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(24),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.folder_open,
//                             size: 64,
//                             color: Colors.grey.shade400,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No Documents',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade700,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Click "Upload" to add your first document',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return RefreshIndicator(
//                   onRefresh: _fetchDocuments,
//                   color: Colors.green,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     itemCount: documents.length,
//                     itemBuilder: (context, index) {
//                       final doc = documents[index];
//                       return _buildDocumentCard(
//                         doc,
//                         () => _openViewModal(doc),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }
// }





import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/data/models/document_model.dart';
import 'package:hosta/providers/document_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// ---------- RESPONSIVE HELPERS ----------
class Responsive {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Scale factor relative to a design baseline (e.g., 375 width)
  static double scaleW(BuildContext context, double size) =>
      size * (screenWidth(context) / 375);
  static double scaleH(BuildContext context, double size) =>
      size * (screenHeight(context) / 812);

  // For consistent spacing
  static double spacing(BuildContext context) => scaleW(context, 8);
  static double spacingL(BuildContext context) => scaleW(context, 16);
  static double spacingXL(BuildContext context) => scaleW(context, 24);
}

// ---------- TAB WIDGET ----------
class DocumentsTab extends ConsumerStatefulWidget {
  const DocumentsTab({Key? key}) : super(key: key);

  @override
  _DocumentsTabState createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<DocumentsTab> {
  static const String s3BaseUrl =
      "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  String? _selectedDate;
  int? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(documentProvider.notifier).init();
    });
    Future.microtask(() {
      ref.read(documentProvider.notifier).fetchDocuments(
        patientId: _selectedPatientId,
        searchQuery: _searchQuery,
        date: _selectedDate,
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String getS3Url(String? key) {
    if (key == null || key.isEmpty) return '';
    const base = "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";
    if (key.startsWith('http')) return key;
    return base + (key.startsWith('/') ? key.substring(1) : key);
  }

  Future<void> _fetchDocuments() async {
    await ref.read(documentProvider.notifier).refresh();
  }

  bool _isImage(Document doc) {
    final type = doc.fileType ?? doc.type ?? '';
    if (type.startsWith('image/')) return true;

    final fileName = doc.fileName ?? '';
    const imageExts = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
    if (imageExts.any((ext) => fileName.toLowerCase().endsWith(ext)))
      return true;

    final url = doc.imageUrl ?? '';
    if (url.isNotEmpty) {
      final lower = url.toLowerCase();
      if (imageExts.any((ext) => lower.endsWith(ext))) return true;
    }
    return false;
  }

  bool _isPDF(Document doc) {
    final type = (doc.fileType ?? doc.type ?? '').toLowerCase();
    final fileName = (doc.fileName ?? '').toLowerCase();
    final url = (doc.imageUrl ?? '').toLowerCase();

    return type.contains('pdf') ||
        fileName.endsWith('.pdf') ||
        url.endsWith('.pdf');
  }

  Icon _getFileIcon(Document doc) {
    if (_isImage(doc)) {
      return const Icon(Icons.image, color: Colors.green, size: 20);
    } else if (_isPDF(doc)) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.blue, size: 20);
    }
  }

  Color _getFileColor(Document doc) {
    if (_isImage(doc)) return Colors.green.shade50;
    if (_isPDF(doc)) return Colors.red.shade50;
    return Colors.blue.shade50;
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.scaleW(context, 10))),
      ),
    );
  }

  void _openUploadModal() {
    final TextEditingController nameController = TextEditingController();
    final patients = ref.read(documentProvider).patients;

    String selectedDate = '';
    File? selectedFile;
    bool isLoading = false;

    int? selectedPatientId =
        ref.read(documentProvider).currentPatientId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            final isTablet = size.width > 600;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Responsive.scaleW(context, 20)),
              ),
              child: Container(
                width: isTablet ? size.width * 0.5 : size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: Responsive.spacingXL(context),
                    right: Responsive.spacingXL(context),
                    top: Responsive.spacingXL(context),
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        Responsive.spacingXL(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.spacing(context) *
                                1.25),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(
                                  Responsive.scaleW(context, 12)),
                            ),
                            child: Icon(
                              Icons.upload_file,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(
                              width: Responsive.spacingL(context) * 0.75),
                          Expanded(
                            child: Text(
                              'Upload Document',
                              style: TextStyle(
                                fontSize: Responsive.scaleW(context, 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.spacingL(context) * 1.25),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Document Name',
                          hintText: 'Enter document name',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                Responsive.scaleW(context, 12)),
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),

                      SizedBox(height: Responsive.spacingL(context)),

                      DropdownButtonFormField<int?>(
                        value: selectedPatientId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Patient",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                Responsive.scaleW(context, 12)),
                          ),
                        ),
                        items: patients.map<DropdownMenuItem<int?>>((patient) {
                          return DropdownMenuItem<int?>(
                            value: patient['id'],
                            child: Text(patient['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedPatientId = value;
                          });
                        },
                      ),

                      SizedBox(height: Responsive.spacingL(context)),

                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            initialDate: DateTime.now(),
                          );

                          if (date != null) {
                            setModalState(() {
                              selectedDate =
                                  DateFormat('yyyy-MM-dd').format(date);
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(Responsive.spacingL(context)),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(
                                Responsive.scaleW(context, 12)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              SizedBox(
                                  width: Responsive.spacingL(context) * 0.75),
                              Expanded(
                                child: Text(
                                  selectedDate.isEmpty
                                      ? 'Select Date'
                                      : DateFormat('dd/MM/yyyy').format(
                                          DateTime.parse(selectedDate),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.spacingL(context)),

                      GestureDetector(
                        onTap: () async {
                          final result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'png',
                              'jpg',
                              'jpeg',
                              'webp',
                              'pdf',
                            ],
                          );

                          if (result != null) {
                            final file = File(result.files.single.path!);

                            final size = await file.length();

                            if (size > 10 * 1024 * 1024) {
                              _showToast(
                                'File size must be less than 10MB',
                                isError: true,
                              );
                              return;
                            }

                            setModalState(() {
                              selectedFile = file;
                            });

                            ref
                                .read(documentProvider.notifier)
                                .setFile(file);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.spacingL(context) *
                              1.25),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(
                                Responsive.scaleW(context, 12)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                selectedFile != null
                                    ? Icons.check_circle
                                    : Icons.cloud_upload,
                                size: Responsive.scaleW(context, 40),
                                color: selectedFile != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              SizedBox(height: Responsive.spacing(context)),
                              Text(
                                selectedFile != null
                                    ? selectedFile!.path.split('/').last
                                    : 'Tap to select Image or PDF',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: Responsive.spacing(context) * 0.5),
                              Text(
                                'Allowed: PNG, JPG, JPEG, WEBP, PDF',
                                style: TextStyle(
                                  fontSize: Responsive.scaleW(context, 11),
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: Responsive.spacingXL(context)),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                          ),

                          SizedBox(width: Responsive.spacingL(context) * 0.75),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: (nameController.text.trim().isEmpty ||
                                      selectedDate.isEmpty ||
                                      selectedFile == null ||
                                      selectedPatientId == null ||
                                      isLoading)
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        final docId = await ref
                                            .read(
                                                documentProvider.notifier)
                                            .createDocument(
                                              name: nameController.text
                                                  .trim(),
                                              date: selectedDate,
                                              patientId:
                                                  selectedPatientId!,
                                            );

                                        if (docId == null) {
                                          throw Exception(
                                              "Failed to create document");
                                        }

                                        await ref
                                            .read(
                                                documentProvider.notifier)
                                            .uploadFileForDocument(
                                              docId: docId,
                                              file: selectedFile!,
                                            );

                                        if (mounted) {
                                          Navigator.pop(context);

                                          _showToast(
                                              "Document uploaded successfully");

                                          await _fetchDocuments();
                                        }
                                      } catch (e) {
                                        setModalState(() {
                                          isLoading = false;
                                        });

                                        _showToast(
                                          e.toString(),
                                          isError: true,
                                        );
                                      }
                                    },
                              child: isLoading
                                  ? SizedBox(
                                      width: Responsive.scaleW(context, 20),
                                      height: Responsive.scaleW(context, 20),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text("Upload"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== EDIT MODAL ====================
  void _openEditModal(Document doc) {
    final TextEditingController nameController =
        TextEditingController(text: doc.name);
    String selectedDate = doc.date;
    File? editFile;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            final isTablet = size.width > 600;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Responsive.scaleW(context, 20)),
              ),
              child: Container(
                width: isTablet ? size.width * 0.5 : size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: Responsive.spacingXL(context),
                    right: Responsive.spacingXL(context),
                    top: Responsive.spacingXL(context),
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        Responsive.spacingXL(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.spacing(context) *
                                1.25),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(
                                  Responsive.scaleW(context, 12)),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(
                              width: Responsive.spacingL(context) * 0.75),
                          Expanded(
                            child: Text(
                              'Edit Document',
                              style: TextStyle(
                                fontSize: Responsive.scaleW(context, 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.spacingL(context) * 1.25),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Document Name',
                          hintText: 'Enter document name',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                Responsive.scaleW(context, 12)),
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      SizedBox(height: Responsive.spacingL(context)),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate.isNotEmpty
                                ? DateTime.parse(selectedDate)
                                : DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );

                          if (date != null) {
                            setModalState(() {
                              selectedDate =
                                  DateFormat('yyyy-MM-dd').format(date);
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(Responsive.spacingL(context)),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(
                                Responsive.scaleW(context, 12)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              SizedBox(
                                  width: Responsive.spacingL(context) * 0.75),
                              Expanded(
                                child: Text(
                                  selectedDate.isEmpty
                                      ? 'Select Date'
                                      : selectedDate,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.spacingL(context)),
                      GestureDetector(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'png',
                              'jpg',
                              'jpeg',
                              'webp',
                              'pdf'
                            ],
                          );

                          if (result != null) {
                            final file = File(result.files.single.path!);
                            final size = await file.length();

                            if (size > 10 * 1024 * 1024) {
                              _showToast(
                                'File size must be < 10MB',
                                isError: true,
                              );
                              return;
                            }

                            setModalState(() {
                              editFile = file;
                            });

                            ref.read(documentProvider.notifier).setFile(file);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Responsive.spacingL(context) *
                              1.25),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(
                                Responsive.scaleW(context, 12)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                editFile != null
                                    ? Icons.check_circle
                                    : Icons.cloud_upload,
                                size: Responsive.scaleW(context, 40),
                                color: editFile != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              SizedBox(height: Responsive.spacing(context)),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  editFile != null
                                      ? editFile!.path.split('/').last
                                      : 'Tap to select a new file (optional)',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: Responsive.spacing(context) * 0.5),
                              Text(
                                'Allowed: PNG, JPG, JPEG, WEBP, PDF',
                                style: TextStyle(
                                  fontSize: Responsive.scaleW(context, 11),
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.spacingXL(context)),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          SizedBox(width: Responsive.spacingL(context) * 0.75),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (nameController.text.isEmpty ||
                                      selectedDate.isEmpty ||
                                      isLoading)
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        await ref
                                            .read(documentProvider.notifier)
                                            .updateDocument(
                                              docId: doc.id.toString(),
                                              name: nameController.text.trim(),
                                              date: selectedDate,
                                            );

                                        if (editFile != null) {
                                          await ref
                                              .read(documentProvider.notifier)
                                              .uploadFileForDocument(
                                                docId: int.parse(
                                                    doc.id.toString()),
                                                file: editFile!,
                                              );
                                        }

                                        if (mounted) {
                                          _showToast(
                                              'Document updated successfully!');
                                          Navigator.pop(context);
                                          await _fetchDocuments();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          _showToast(
                                            'Failed to update document: ${e.toString()}',
                                            isError: true,
                                          );
                                        }
                                        setModalState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                              child: isLoading
                                  ? SizedBox(
                                      width: Responsive.scaleW(context, 20),
                                      height: Responsive.scaleW(context, 20),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Update'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== DOCUMENT CARD ====================
  Widget _buildDocumentCard(Document doc, VoidCallback onTap) {
    final hasFile = doc.imageUrl != null && doc.imageUrl!.isNotEmpty;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.spacingL(context),
        vertical: Responsive.spacing(context) * 0.5,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.scaleW(context, 12)),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Responsive.scaleW(context, 12)),
        onTap: hasFile ? onTap : null,
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacingL(context) * 0.75),
          child: Row(
            children: [
              Container(
                width: Responsive.scaleW(context, 44),
                height: Responsive.scaleW(context, 44),
                decoration: BoxDecoration(
                  color: _getFileColor(doc),
                  borderRadius: BorderRadius.circular(
                      Responsive.scaleW(context, 10)),
                ),
                child: _getFileIcon(doc),
              ),
              SizedBox(width: Responsive.spacingL(context) * 0.75),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.scaleW(context, 14),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    SizedBox(height: Responsive.spacing(context) * 0.25),
                    Text(
                      doc.date.isNotEmpty
                          ? DateFormat('yyyy-MM-dd')
                              .format(DateTime.parse(doc.date))
                          : 'N/A',
                      style: TextStyle(
                        fontSize: Responsive.scaleW(context, 12),
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      if (hasFile) onTap();
                      break;
                    case 'edit':
                      _openEditModal(doc);
                      break;
                    case 'delete':
                      _handleDelete(doc);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    enabled: hasFile,
                    child: Row(
                      children: [
                        Icon(Icons.visibility,
                            size: Responsive.scaleW(context, 18),
                            color: hasFile ? null : Colors.grey),
                        SizedBox(width: Responsive.spacing(context)),
                        Text('View',
                            style: TextStyle(
                                color: hasFile ? null : Colors.grey)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== DELETE ====================
  Future<void> _handleDelete(Document doc) async {
    if (doc.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                Responsive.scaleW(context, 16))),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context)),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(
                    Responsive.scaleW(context, 8)),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red.shade700),
            ),
            SizedBox(width: Responsive.spacingL(context) * 0.75),
            Expanded(
              child: Text(
                'Delete Document',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${doc.name}"?',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Responsive.scaleW(context, 8)),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(documentProvider.notifier).deleteDocument(
            id: int.parse(doc.id.toString()),
          );
      if (mounted) {
        _showToast('Document deleted successfully');
        await _fetchDocuments();
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to delete document', isError: true);
      }
    }
  }

  void _openViewModal(Document doc) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _buildViewModal(doc),
    );
  }

  Widget _buildViewModal(Document doc) {
    final fileUrl = getS3Url(doc.imageUrl);
    final isPdf = _isPDF(doc);
    final isImg = _isImage(doc);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
          horizontal: Responsive.scaleW(context, 10),
          vertical: Responsive.scaleH(context, 20)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            Responsive.scaleW(context, 20)),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(Responsive.spacingL(context)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(context)),
                  decoration: BoxDecoration(
                    color: _getFileColor(doc),
                    borderRadius: BorderRadius.circular(
                        Responsive.scaleW(context, 10)),
                  ),
                  child: _getFileIcon(doc),
                ),
                SizedBox(width: Responsive.spacingL(context) * 0.75),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: TextStyle(
                          fontSize: Responsive.scaleW(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        doc.date.isNotEmpty
                            ? DateFormat.yMMMd()
                                .format(DateTime.parse(doc.date))
                            : 'N/A',
                        style: TextStyle(
                          fontSize: Responsive.scaleW(context, 13),
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: Responsive.spacingL(context)),
            Expanded(
              child: fileUrl.isEmpty
                  ? const Center(child: Text('No file attached'))
                  : isPdf
                      ? SfPdfViewer.network(
                          fileUrl,
                          canShowScrollStatus: true,
                          canShowPaginationDialog: true,
                        )
                      : isImg
                          ? InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.network(
                                fileUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          size: 64, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Unable to load image'),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.insert_drive_file,
                                      size: Responsive.scaleW(context, 80),
                                      color: Colors.blue.shade300),
                                  SizedBox(height: Responsive.spacingL(context)),
                                  Text(
                                    doc.fileName ?? 'Document',
                                    style: TextStyle(
                                        fontSize: Responsive.scaleW(context, 16),
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: Responsive.spacingL(context)),
                                  ElevatedButton.icon(
                                    onPressed: () => _launchURL(fileUrl),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Open Document'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            Responsive.scaleW(context, 10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
            ),
            SizedBox(height: Responsive.spacing(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (fileUrl.isNotEmpty && !isPdf)
                  TextButton.icon(
                    onPressed: () => _launchURL(fileUrl),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open in Browser'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                SizedBox(width: Responsive.spacing(context)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showToast('Cannot open link', isError: true);
      }
    } catch (e) {
      _showToast('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents =
        ref.watch(documentProvider.select((state) => state.documents));
    final isLoading =
        ref.watch(documentProvider.select((state) => state.isLoading));
    final error = ref.watch(documentProvider.select((state) => state.error));
    final patients =
        ref.watch(documentProvider.select((s) => s.patients));

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "My Documents",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.scaleW(context, 18),
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.spacingL(context),
                vertical: Responsive.spacingL(context) * 0.75),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: Responsive.scaleW(context, 4),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.spacing(context)),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(
                            Responsive.scaleW(context, 10)),
                      ),
                      child: Icon(Icons.folder, color: Colors.green.shade700),
                    ),
                    SizedBox(width: Responsive.spacingL(context) * 0.75),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Documents',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                            fontSize: Responsive.scaleW(context, 14),
                          ),
                        ),
                        Text(
                          '${documents.length} files',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.scaleW(context, 16),
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final patientId =
                        ref.read(documentProvider).currentPatientId;

                    if (patientId == null) {
                      _showToast(
                        'Only patients who have completed consultation can upload documents.',
                        isError: true,
                      );
                      return;
                    }
                    _openUploadModal();
                  },
                  icon: Icon(Icons.upload_file,
                      size: Responsive.scaleW(context, 18)),
                  label: Text(
                    "Upload",
                    style: TextStyle(fontSize: Responsive.scaleW(context, 14)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          Responsive.scaleW(context, 10)),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.spacingL(context),
                        vertical: Responsive.spacingL(context) * 0.625),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                Responsive.spacingL(context),
                Responsive.spacingL(context) * 0.75,
                Responsive.spacingL(context),
                Responsive.spacing(context) * 0.5),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });

                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        ref.read(documentProvider.notifier).fetchDocuments(
                          patientId: _selectedPatientId,
                          searchQuery: value,
                          date: _selectedDate,
                        );
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search documents...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchQuery = '';
                                });

                                ref.read(documentProvider.notifier)
                                    .fetchDocuments(
                                      patientId: _selectedPatientId,
                                      searchQuery: '',
                                      date: _selectedDate,
                                    );
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            Responsive.scaleW(context, 12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacingL(context) * 0.75,
                          vertical: Responsive.spacingL(context) * 0.875),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.spacingL(context) * 0.625),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setState(() {
                          _selectedDate =
                              DateFormat('yyyy-MM-dd').format(picked);
                        });

                        ref.read(documentProvider.notifier).fetchDocuments(
                          patientId: _selectedPatientId,
                          searchQuery: _searchQuery,
                          date: _selectedDate,
                        );
                      }
                    },
                    child: Container(
                      height: Responsive.scaleH(context, 56),
                      padding: EdgeInsets.symmetric(
                          horizontal: Responsive.spacingL(context) * 0.75),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(
                            Responsive.scaleW(context, 12)),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: Responsive.scaleW(context, 18)),
                          SizedBox(width: Responsive.spacing(context) * 0.5),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? "Date"
                                  : DateFormat('dd/MM/yyyy')
                                      .format(DateTime.parse(_selectedDate!)),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: Responsive.scaleW(context, 14)),
                            ),
                          ),
                          if (_selectedDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = null;
                                });

                                ref.read(documentProvider.notifier)
                                    .fetchDocuments(
                                      patientId: _selectedPatientId,
                                      searchQuery: _searchQuery,
                                      date: null,
                                    );
                              },
                              child: Icon(Icons.close,
                                  size: Responsive.scaleW(context, 18)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonFormField<int?>(
            value: _selectedPatientId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Patient",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    Responsive.scaleW(context, 12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                    Responsive.scaleW(context, 12)),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(
                  color: Colors.green,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: Responsive.spacingL(context) * 0.75,
                  vertical: Responsive.spacingL(context) * 0.875),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("All Patients"),
              ),
              ...patients.map<DropdownMenuItem<int?>>((patient) {
                return DropdownMenuItem<int?>(
                  value: patient['id'],
                  child: Text(patient['name']),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPatientId = value;
              });

              ref.read(documentProvider.notifier).fetchDocuments(
                patientId: value,
                searchQuery: _searchQuery,
                date: _selectedDate,
              );
            },
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 16),
                        Text('Loading documents...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                if (error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: Responsive.scaleW(context, 64),
                            color: Colors.grey.shade400),
                        SizedBox(height: Responsive.spacingL(context)),
                        Text(
                          'Error loading documents',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: Responsive.scaleW(context, 16),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context)),
                        Text(
                          error,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: Responsive.scaleW(context, 14)),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Responsive.spacingL(context)),
                        ElevatedButton.icon(
                          onPressed: _fetchDocuments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (documents.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.spacingXL(
                                context)),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.folder_open,
                              size: Responsive.scaleW(context, 64),
                              color: Colors.grey.shade400,
                            ),
                          ),
                          SizedBox(height: Responsive.spacingL(context)),
                          Text(
                            'No Documents',
                            style: TextStyle(
                              fontSize: Responsive.scaleW(context, 20),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: Responsive.spacing(context)),
                          Text(
                            'Click "Upload" to add your first document',
                            style: TextStyle(
                              fontSize: Responsive.scaleW(context, 14),
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(documentProvider.notifier).fetchDocuments(
                      patientId: _selectedPatientId,
                      searchQuery: _searchQuery,
                      date: _selectedDate,
                    );
                  },
                  color: Colors.green,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                        vertical: Responsive.spacing(context)),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];

                      return _buildDocumentCard(
                        doc,
                        () => _openViewModal(doc),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

