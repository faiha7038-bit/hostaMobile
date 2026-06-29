// lib/presentation/screens/document/document_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hosta/data/models/document_model.dart';
import 'package:hosta/presentation/screens/document/document_view.dart';
import 'package:hosta/presentation/widgets/document_card.dart';
import 'package:hosta/services/document_service.dart';
import 'dart:io';

class DocumentScreen extends StatefulWidget {
  final String patientId;

  const DocumentScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final DocumentService _documentService = DocumentService();
  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocuments = []; // ✅ Filtered list
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = ''; // ✅ Search query
  late final List<String> _filters;

  @override
  void initState() {
    super.initState();
    _filters = ['All', ...DocumentType.allTypes];
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _documentService.getDocuments(widget.patientId);
      setState(() {
        _documents = docs;
        _filteredDocuments = docs; // ✅ Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ Filter documents based on search and filter
  void _filterDocuments() {
    setState(() {
      _filteredDocuments = _documents.where((doc) {
        // Filter by type
        final matchesFilter = _selectedFilter == 'All' || 
            doc.documentType == _selectedFilter;
        
        // Filter by search query
        final matchesSearch = _searchQuery.isEmpty ||
            doc.fileName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doc.documentType.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _viewDocument(DocumentModel doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(
          document: doc,
        ),
      ),
    );
  }

  void _downloadDocument(DocumentModel doc) async {
    try {
      final filePath = await _documentService.downloadDocument(doc);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document downloaded successfully!'),
          backgroundColor:Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${doc.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _documentService.deleteDocument(doc.id);
        if (success) {
          setState(() {
            _documents.removeWhere((d) => d.id == doc.id);
            _filterDocuments(); // ✅ Refresh filtered list
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor:Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'My Documents',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
       
      ),
      body: Column(
        children: [
          // ✅ Search Bar - AppBar-ൽ നിന്ന് താഴേക്ക്
          _buildSearchBar(),
          
          // ✅ Filter Chips
          _buildFilterChips(),
          
          // ✅ Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color:Colors.green,
                    ),
                  )
                : _filteredDocuments.isEmpty
                    ? _buildEmptyState()
                    : _buildDocumentList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:Colors.green,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () => _showUploadDialog(),
      ),
    );
  }

  // ✅ Search Bar Widget
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchQuery.isNotEmpty 
                      ?  Colors.green
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterDocuments(); // ✅ Filter on search
                  });
                },
                controller: TextEditingController(text: _searchQuery),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _filterDocuments();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  // Search on submit
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ✅ Search count
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredDocuments.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Focus search
  void _focusSearch() {
    // Scroll to search bar
    // You can use ScrollController if needed
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No results found' 
                : 'No Documents Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching with different keywords'
                : 'Upload your medical documents for easy access',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (!_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:  Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showUploadDialog(),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                'Upload Document',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDocuments.length,
      itemBuilder: (context, index) {
        final doc = _filteredDocuments[index];
        return DocumentCard(
          document: doc,
          onTap: () => _viewDocument(doc),
          onDownload: () => _downloadDocument(doc),
          onDelete: () => _deleteDocument(doc),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.green.withOpacity(0.2),
              checkmarkColor: Colors.green,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _filterDocuments(); // ✅ Filter on type change
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected 
                      ? const Color(0xFF2E7D32) 
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            _buildUploadOption(
              icon: Icons.photo_library,
              title: 'Gallery',
              subtitle: 'Choose from photos',
              color: Colors.purple,
              onTap: () => _pickFile(DocumentPickType.image),
            ),
            _buildUploadOption(
              icon: Icons.picture_as_pdf,
              title: 'PDF',
              subtitle: 'Upload PDF files',
              color: Colors.red,
              onTap: () => _pickFile(DocumentPickType.pdf),
            ),
            _buildUploadOption(
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take a photo',
              color: Colors.blue,
              onTap: () => _takePhoto(),
            ),
            _buildUploadOption(
              icon: Icons.folder,
              title: 'Browse',
              subtitle: 'Browse files',
              color: Colors.green,
              onTap: () => _pickFile(DocumentPickType.any),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Future<void> _pickFile(DocumentPickType type) async {
    FilePickerResult? result;
    
    try {
      switch (type) {
        case DocumentPickType.image:
          result = await FilePicker.pickFiles(
            type: FileType.image,
            allowMultiple: false,
          );
          break;
        case DocumentPickType.pdf:
          result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );
          break;
        case DocumentPickType.any:
          result = await FilePicker.pickFiles(
            allowMultiple: false,
          );
          break;
      }

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        await _uploadDocument(file, fileName);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera feature coming soon...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _uploadDocument(File file, String fileName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color:Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Uploading...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      final type = await _showDocumentTypeDialog();
      
      if (type != null) {
        final newDoc = await _documentService.uploadDocument(
          patientId: widget.patientId,
          file: file,
          fileName: fileName,
          documentType: type,
        );
        
        if (mounted) Navigator.pop(context);
        
        setState(() {
          _documents.insert(0, newDoc);
          _filterDocuments(); // ✅ Refresh filtered list
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor:Colors.green,
          ),
        );
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showDocumentTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Select Document Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DocumentType.allTypes.map((type) {
            return ListTile(
              title: Text(type),
              onTap: () => Navigator.pop(context, type),
              leading: Icon(
                _getTypeIcon(type),
                color: _getTypeColor(type),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Prescription':
        return Icons.medication;
      case 'Lab Report':
        return Icons.science;
      case 'Medical History':
        return Icons.history;
      case 'Insurance':
        return Icons.assignment;
      default:
        return Icons.description;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Prescription':
        return const Color(0xFF2E7D32);
      case 'Lab Report':
        return const Color(0xFF1565C0);
      case 'Medical History':
        return const Color(0xFFF57C00);
      case 'Insurance':
        return const Color(0xFF6A1B9A);
      default:
        return Colors.grey;
    }
  }
}

// ✅ Enum
enum DocumentPickType { image, pdf, any }