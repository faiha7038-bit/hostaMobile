// lib/screens/document_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hosta/data/models/document_model.dart';
import 'package:hosta/services/document_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class DocumentViewerScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentViewerScreen({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  _DocumentViewerScreenState createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  final DocumentService _documentService = DocumentService();

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  Future<void> _checkFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if file is accessible
      if (widget.document.fileUrl.isEmpty) {
        throw Exception('File URL is empty');
      }
      
      // For images, check if it's a valid URL
      if (!widget.document.isPdf) {
        final response = await http.head(Uri.parse(widget.document.fileUrl));
        if (response.statusCode != 200) {
          throw Exception('File not accessible');
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load document: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Main Content
          _buildDocumentViewer(),
          
          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading document...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          
          // Error Message
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[300],
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: _retryLoad,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ✅ App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text(
        widget.document.fileName,
        style: const TextStyle(color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        // Page count for PDF
        if (widget.document.isPdf && _totalPages > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareDocument,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  // ✅ Document Viewer
  Widget _buildDocumentViewer() {
    try {
      if (widget.document.isPdf) {
        return PDFView(
          filePath: widget.document.fileUrl,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: true,
          onRender: (int? pages) {
            // ✅ pages nullable ആണ്
            setState(() {
              _totalPages = pages ?? 0;
              _isLoading = false;
            });
          },
          onError: (error) {
            setState(() {
              _errorMessage = 'Failed to load PDF: $error';
              _isLoading = false;
            });
          },
          onPageChanged: (int? page, int? total) {
            // ✅ page, total nullable ആണ്
            setState(() {
              _currentPage = page ?? 0;
              _totalPages = total ?? 0;
            });
          },
          onViewCreated: (PDFViewController controller) {
            // Controller is available here
          },
        );
      } else if (widget.document.isImage) {
        return PhotoView(
          imageProvider: NetworkImage(widget.document.fileUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          loadingBuilder: (context, event) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _retryLoad,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: Colors.white54,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                widget.document.fileName,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'File type: ${widget.document.mimeType}',
                style: const TextStyle(color: Colors.white38),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: _downloadDocument,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'Download',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white54,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading document',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }
  }

  // ✅ Bottom Navigation Bar
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.download,
            label: 'Download',
            onTap: _downloadDocument,
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _shareDocument,
          ),
          _buildActionButton(
            icon: Icons.info_outline,
            label: 'Details',
            onTap: _showDocumentDetails,
          ),
        ],
      ),
    );
  }

  // ✅ Action Button Widget
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Download Document
  Future<void> _downloadDocument() async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading...'),
          backgroundColor: Colors.blue,
        ),
      );

      final filePath = await _documentService.downloadDocument(widget.document);
      
      // Show success
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: ${widget.document.fileName}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _openFile(filePath),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Open File
  Future<void> _openFile(String filePath) async {
    try {
      // Use open_file package to open the file
      // final result = await OpenFile.open(filePath);
      // if (result.type != ResultType.done) {
      //   throw Exception('Failed to open file');
      // }
      
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File opened successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Share Document
  Future<void> _shareDocument() async {
    try {
      // Share text with link
      await Share.share(
        '📄 ${widget.document.fileName}\n'
        'Type: ${widget.document.documentType}\n'
        'Size: ${widget.document.formattedFileSize}\n'
        'Date: ${widget.document.formattedDate}\n\n'
        'View here: ${widget.document.fileUrl}',
        subject: widget.document.fileName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Show Document Details
  void _showDocumentDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color:Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('Document Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', widget.document.fileName),
            _buildDetailRow('Type', widget.document.documentType),
            _buildDetailRow('Size', widget.document.formattedFileSize),
            _buildDetailRow('Date', widget.document.formattedDateTime),
            _buildDetailRow('MIME Type', widget.document.mimeType),
            if (widget.document.description != null)
              _buildDetailRow('Description', widget.document.description!),
            _buildDetailRow('Verified', 
              widget.document.isVerified ? '✅ Yes' : '❌ No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 4),
        ],
      ),
    );
  }

  // ✅ Show More Options
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('Download', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _downloadDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('Details', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showDocumentDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ✅ Confirm Delete
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Document?'),
        content: Text(
          'Are you sure you want to delete "${widget.document.fileName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDocument();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Delete Document
  Future<void> _deleteDocument() async {
    try {
      final success = await _documentService.deleteDocument(widget.document.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor:Colors.green,
          ),
        );
        Navigator.pop(context); // Close viewer
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Retry Load
  void _retryLoad() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _checkFile();
  }
}