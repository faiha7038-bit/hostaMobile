// lib/widgets/document_card.dart

import 'package:flutter/material.dart';
import 'package:hosta/data/models/document_model.dart';


class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const DocumentCard({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Document Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getDocumentColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDocumentIcon(),
              color: _getDocumentColor(),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Type Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDocumentColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        document.documentType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getDocumentColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ formattedFileSize
                    Text(
                      document.formattedFileSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    // ✅ formattedDate
                    Text(
                      document.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () => _showOptions(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.download, color:Colors.green, size: 20),
                onPressed: onDownload,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon() {
    switch (document.documentType) {
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

  Color _getDocumentColor() {
    switch (document.documentType) {
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

  void _showOptions(BuildContext context) {
    // Show options
  }
}