import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/data/models/document_model.dart';
import 'package:hosta/presentation/screens/document/widgets/toast.dart';
import 'package:hosta/providers/document_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentsTab extends ConsumerStatefulWidget {
  const DocumentsTab({Key? key}) : super(key: key);

  @override
  _DocumentsTabState createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<DocumentsTab> {
  static const String s3BaseUrl =
      "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";

  bool _isSubmitting = false;
  String _documentName = '';
  String _documentDate = '';
  File? _selectedFile;
  Document? _editingDocument;
  File? _editFile;
  bool _showUploadModal = false;
  bool _showEditModal = false;
  bool _showViewModal = false;
  int _uploadProgress = 0;
  String _editDocumentName = '';
  String _editDocumentDate = '';
  Document? _viewingDocument;
  int userId = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(documentProvider.notifier).init();
    });
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

  // ---------- CREATE ----------
  Future<void> _handleCreate() async {
    if (_selectedFile == null) return;

    final notifier = ref.read(documentProvider.notifier);
    notifier.setFile(_selectedFile!);

    await notifier.createDocument(
      name: _documentName,
      date: _documentDate,
      patientId: 0, // ignored
    );

    _closeUploadModal();
  }

  // ---------- UPDATE ----------
  Future<void> _handleUpdate() async {
    final doc = _editingDocument;
    if (doc == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(documentProvider.notifier).updateDocument(
            docId: doc.id.toString(),
            name: _editDocumentName,
            date: _editDocumentDate,
          );

      _closeEditModal();
      await _fetchDocuments();
    } catch (e) {
      showToast("Update failed: $e", isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ---------- DELETE ----------
  Future<void> _handleDelete(Document doc) async {
    if (doc.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;
    await ref.read(documentProvider.notifier).deleteDocument(
          id: int.parse(doc.id.toString()),
          // role and key removed
        );
  }

  // ---------- VIEW ----------
  void _openViewModal(Document doc) {
    // setState(() {
    //   _viewingDocument = doc;
    // });

    showDialog(
      context: context,
      builder: (ctx) => _buildViewModal(doc),
    );
  }

  // ---------- HELPERS ----------
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
      return const Icon(Icons.image, color: Colors.green, size: 16);
    } else if (_isPDF(doc)) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red, size: 16);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.blue, size: 16);
    }
  }

  void _openUploadModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        String docName = '';
        String docDate = '';
        File? selectedFile;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Responsive dimensions
            final double width = MediaQuery.of(context).size.width * 0.9;
            final double height = MediaQuery.of(context).size.height * 0.7;
            final double maxWidth = width > 600 ? 600 : width;

            return AlertDialog(
              title: const Text('Create Document'),
              content: SizedBox(
                width: maxWidth,
                height: height,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Document Name *',
                        ),
                        onChanged: (v) => setModalState(() => docName = v),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: docDate),
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                          hintText: 'Select Date',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            initialDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() {
                              docDate = DateFormat('yyyy-MM-dd').format(date);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
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
                              showToast('File size must be < 10MB',
                                  isError: true);
                              return;
                            }
                            setModalState(() => selectedFile = file);
                            ref.read(documentProvider.notifier).setFile(file);
                          }
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 120),
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                selectedFile != null
                                    ? Icons.check_circle
                                    : Icons.cloud_upload,
                                color: selectedFile != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedFile != null
                                    ? selectedFile!.path.split('/').last
                                    : 'Tap to select Image or PDF',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Allowed: PNG, JPG, JPEG, WEBP, PDF (Max 10MB)',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (docName.isEmpty ||
                          docDate.isEmpty ||
                          selectedFile == null ||
                          isLoading)
                      ? null
                      : () async {
                          setModalState(() => isLoading = true);
                          final notifier = ref.read(documentProvider.notifier);
                          final patientId =
                              ref.read(documentProvider).currentPatientId;

                          if (patientId == null) {
                            showToast("No patient found!", isError: true);
                            setModalState(() => isLoading = false);
                            return;
                          }

                          // 1️⃣ Create document (fast – just DB entry)
                          final docId = await notifier.createDocument(
                            name: docName,
                            date: docDate,
                            patientId: patientId,
                          );

                          // 2️⃣ Stop loading & close modal immediately
                          setModalState(() => isLoading = false);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }

                          // 3️⃣ Upload file in the background and refresh list when done
                          if (docId != null && selectedFile != null) {
                            notifier
                                .uploadFileForDocument(
                              docId: docId,
                              file: selectedFile!,
                            )
                                .then((_) {
                              // 🔄 Refresh the document list after upload completes
                              if (context.mounted) {
                                ref.read(documentProvider.notifier).refresh();
                              }
                            }).catchError((e) {
                              if (context.mounted) {
                                showToast("File upload failed: $e",
                                    isError: true);
                              }
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _closeUploadModal() {
    setState(() {
      _showUploadModal = false;
      _documentName = '';
      _documentDate = '';
    });
  }

  void _openEditModal(Document doc) {
    showDialog(
      context: context,
      builder: (ctx) {
        String editName = doc.name;
        String editDate = doc.date;
        File? editFile;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Responsive dimensions
            final double width = MediaQuery.of(context).size.width * 0.9;
            final double height = MediaQuery.of(context).size.height * 0.7;
            final double maxWidth = width > 600 ? 600 : width;

            return AlertDialog(
              title: const Text('Edit Document'),
              content: SizedBox(
                width: maxWidth,
                height: height,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration:
                            const InputDecoration(labelText: 'Document Name *'),
                        controller: TextEditingController(text: editName)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: editName.length),
                          ),
                        onChanged: (v) => setModalState(() => editName = v),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: editDate),
                        decoration: const InputDecoration(labelText: 'Date *'),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: editDate.isNotEmpty
                                ? DateTime.parse(editDate)
                                : DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() {
                              editDate = DateFormat('yyyy-MM-dd').format(date);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
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
                            setModalState(() => editFile = file);
                            ref.read(documentProvider.notifier).setFile(file);
                          }
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 120),
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                editFile != null
                                    ? Icons.check_circle
                                    : Icons.cloud_upload,
                                color: editFile != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                editFile != null
                                    ? editFile!.path.split('/').last
                                    : 'Click to select new file (optional)',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (editName.isEmpty || editDate.isEmpty || isLoading)
                      ? null
                      : () async {
                          setModalState(() => isLoading = true);
                          final notifier = ref.read(documentProvider.notifier);

                          // 1️⃣ Update document details (fast)
                          await notifier.updateDocument(
                            docId: doc.id.toString(),
                            name: editName,
                            date: editDate,
                          );

                          // 2️⃣ Stop loading & close modal immediately
                          setModalState(() => isLoading = false);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }

                          // 3️⃣ Upload new file in the background and refresh list when done
                          if (editFile != null) {
                            notifier
                                .uploadFileForDocument(
                              docId: int.parse(doc.id.toString()),
                              file: editFile!,
                            )
                                .then((_) {
                              if (context.mounted) {
                                ref.read(documentProvider.notifier).refresh();
                              }
                            }).catchError((e) {
                              if (context.mounted) {
                                // showToast("File upload failed: $e", isError: true);
                              }
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _closeEditModal() {
    setState(() {
      _showEditModal = false;
      _editingDocument = null;
      _editDocumentName = '';
      _editDocumentDate = '';
      _editFile = null;
      _uploadProgress = 0;
    });
  }

  void _closeViewModal() {
    setState(() {
      _showViewModal = false;
      _viewingDocument = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final size = await file.length();
    const maxSize = 10 * 1024 * 1024;

    if (size > maxSize) {
      // showToast('File size must be less than 10MB', isError: true);
      return;
    }

    setState(() {
      _selectedFile = file;
    });

    ref.read(documentProvider.notifier).setFile(file);
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Use select to watch only the needed parts
    final documents =
        ref.watch(documentProvider.select((state) => state.documents));
    final isLoading =
        ref.watch(documentProvider.select((state) => state.isLoading));
    final error = ref.watch(documentProvider.select((state) => state.error));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          " My Documents",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Total Documents',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${documents.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openUploadModal,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Content area – Expanded to prevent overflow
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_document,
                              color: Colors.grey, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'No Documents Found',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 18),
                          ),
                          // Text('Error: $error'),
                          // ElevatedButton(
                          //   onPressed: _fetchDocuments,
                          //   child: const Text('Retry'),
                          // ),
                        ],
                      ),
                    ),
                  );
                } else if (documents.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_present,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No documents found'),
                          Text(
                            'Click "Upload Document" to add files',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor:
                            MaterialStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Document Name')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text(''), numeric: true),
                        ],
                        rows: documents.map((doc) {
                          final hasFile =
                              doc.imageUrl != null && doc.imageUrl!.isNotEmpty;

                          return DataRow(cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _getFileIcon(doc),
                                  const SizedBox(width: 6),
                                  Text(doc.name),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(doc.date.isNotEmpty
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(DateTime.parse(doc.date))
                                  : 'N/A'),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon:
                                        const Icon(Icons.visibility, size: 18),
                                    color: Colors.grey,
                                    onPressed: hasFile
                                        ? () => _openViewModal(doc)
                                        : null,
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _openEditModal(doc);
                                          break;
                                        case 'delete':
                                          _handleDelete(doc);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) {
                                      final items = <PopupMenuItem<String>>[
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                      ];
                                      if (doc.id != null) {
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 18,
                                                    color: Colors.black),
                                                SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return items;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- DIALOGS ----------

  // Upload Modal (Create) – kept for reference, but not used (the actual dialog is in _openUploadModal)
  Widget _buildUploadModal() {
    return AlertDialog(
      title: const Text('Create Document'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Document Name *',
                ),
                onChanged: (v) => setState(() => _documentName = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date *',
                  hintText:
                      _documentDate.isEmpty ? 'Select Date' : _documentDate,
                ),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _documentDate = DateFormat('yyyy-MM-dd').format(date);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.check_circle
                            : Icons.cloud_upload,
                        color:
                            _selectedFile != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null
                            ? _selectedFile!.path.split('/').last
                            : 'Tap to select Image or PDF',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Allowed: PNG, JPG, JPEG, WEBP, PDF ',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_documentName.isEmpty ||
                  _documentDate.isEmpty ||
                  _selectedFile == null)
              ? null
              : _handleCreate,
          child: const Text("Create"),
        ),
      ],
    );
  }

  // Edit Modal – kept for reference, but not used (the actual dialog is in _openEditModal)
  Widget _buildEditModal() {
    return AlertDialog(
      title: const Text('Edit Document'),
      content: SizedBox(
        width: 450,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Document Name *',
                  hintText: 'e.g., Medical Report, Prescription',
                ),
                controller: TextEditingController(text: _editDocumentName)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _editDocumentName.length),
                  ),
                onChanged: (v) => setState(() => _editDocumentName = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  hintText: 'YYYY-MM-DD',
                ),
                readOnly: true,
                controller: TextEditingController(text: _editDocumentDate),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _editDocumentDate.isNotEmpty
                        ? DateTime.parse(_editDocumentDate)
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _editDocumentDate = DateFormat('yyyy-MM-dd').format(date);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_editingDocument?.imageUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_editingDocument?.imageUrl?.isNotEmpty == true)
                        Image.network(
                          getS3Url(_editingDocument!.imageUrl),
                          height: 48,
                          width: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 48),
                        )
                      else
                        const Icon(Icons.insert_drive_file,
                            size: 48, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingDocument?.fileName ?? 'File',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${_editingDocument?.fileSize ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _closeEditModal();
                          _openViewModal(_editingDocument!);
                        },
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GestureDetector(
                onTap: _isSubmitting ? null : _pickFile,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _editFile != null
                            ? Icons.check_circle
                            : Icons.cloud_upload,
                        color: _editFile != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _editFile != null
                            ? _editFile!.path.split('/').last
                            : 'Click to select a new file (optional)',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'Images (PNG, JPEG, WEBP) or PDF (Max 10MB)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isSubmitting && _uploadProgress > 0) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _uploadProgress / 100),
                const SizedBox(height: 4),
                Text('$_uploadProgress%', style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _closeEditModal,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isSubmitting ||
                  _editDocumentName.trim().isEmpty ||
                  _editDocumentDate.isEmpty)
              ? null
              : _handleUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C62A0),
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  // View Modal – now fully responsive
  Widget _buildViewModal(Document doc) {
    final fileUrl = getS3Url(doc.imageUrl);
    final isPdf = _isPDF(doc);
    final isImg = _isImage(doc);
    log("===== VIEW MODAL DEBUG =====");
    log("NAME => ${doc.name}");
    log("RAW URL => ${doc.imageUrl}");
    log("FINAL URL => $fileUrl");
    log("IS PDF => $isPdf");
    log("IS IMAGE => $isImg");

    return AlertDialog(
      title: Text(doc.name, overflow: TextOverflow.ellipsis),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: fileUrl.isEmpty
                  ? const Center(child: Text('No file attached'))
                  : isPdf
                      ? _buildPDFViewer(fileUrl)
                      : isImg
                          ? _buildImageViewer(fileUrl)
                          : _buildGenericViewer(fileUrl),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Date: ${doc.date.isNotEmpty ? DateFormat.yMMMd().format(DateTime.parse(doc.date)) : 'N/A'}'),
                Row(
                  children: [
                    if (fileUrl.isNotEmpty && !isPdf)
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _launchURL(fileUrl),
                        tooltip: 'Open in browser',
                      ),
                    // IconButton(
                    //   icon: const Icon(Icons.download),
                    //   onPressed: fileUrl.isNotEmpty
                    //       ? () => _downloadDocument(doc)
                    //       : null,
                    // ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildPDFViewer(String url) {
    return SfPdfViewer.network(
      url,
      canShowScrollStatus: true,
      canShowPaginationDialog: true,
    );
  }

  Widget _buildImageViewer(String url) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.grey),
              Text('Unable to load image'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenericViewer(String url) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text(_viewingDocument?.fileName ?? 'Document'),
          ElevatedButton(
            onPressed: () => _launchURL(url),
            child: const Text('Open Document'),
          ),
        ],
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
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        } else {
          showToast('No browser available', isError: true);
        }
      }
    } catch (e) {
      showToast('Error: $e', isError: true);
    }
  }

  void _downloadDocument(Document doc) {
    showToast('Download: ${doc.fileName ?? doc.name}', isWarning: true);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
