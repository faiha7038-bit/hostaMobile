// import 'dart:async';
// import 'dart:io';
// import 'package:hosta/data/models/document_model.dart';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path_provider/path_provider.dart';


// class StorageService {
//   static final StorageService _instance = StorageService._internal();
//   factory StorageService() => _instance;
//   StorageService._internal();

//   static Database? _database;

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = join(documentsDirectory.path, 'health_documents.db');
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: _onCreate,
//     );
//   }

//   Future<void> _onCreate(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE documents (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         name TEXT NOT NULL,
//         type TEXT NOT NULL,
//         filePath TEXT NOT NULL,
//         date TEXT NOT NULL,
//         fileSize TEXT NOT NULL,
//         description TEXT,
//         doctorName TEXT
//       )
//     ''');
//   }

//   // Insert document
//   Future<int> insertDocument(DocumentModel document) async {
//     Database db = await database;
//     return await db.insert('documents', document.toMap());
//   }

//   // Get all documents
//   Future<List<DocumentModel>> getAllDocuments() async {
//     Database db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'documents',
//       orderBy: 'id DESC',
//     );
//     return List.generate(maps.length, (i) {
//       return DocumentModel.fromMap(maps[i]);
//     });
//   }

//   // Get documents by type
//   Future<List<DocumentModel>> getDocumentsByType(String type) async {
//     Database db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'documents',
//       where: 'type = ?',
//       whereArgs: [type],
//       orderBy: 'id DESC',
//     );
//     return List.generate(maps.length, (i) {
//       return DocumentModel.fromMap(maps[i]);
//     });
//   }

//   // Delete document
//   Future<int> deleteDocument(int id) async {
//     Database db = await database;
//     return await db.delete(
//       'documents',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }

//   // Delete document with file
//   Future<void> deleteDocumentWithFile(int id) async {
//     DocumentModel? doc = await getDocumentById(id);
//     if (doc != null) {
//       // Delete file from storage
//       try {
//         File file = File(doc.filePath);
//         if (await file.exists()) {
//           await file.delete();
//         }
//       } catch (e) {
//         print('Error deleting file: $e');
//       }
//       // Delete from database
//       await deleteDocument(id);
//     }
//   }

//   // Get document by ID
//   Future<DocumentModel?> getDocumentById(int id) async {
//     Database db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'documents',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//     if (maps.isNotEmpty) {
//       return DocumentModel.fromMap(maps.first);
//     }
//     return null;
//   }

//   // Update document
//   Future<int> updateDocument(DocumentModel document) async {
//     Database db = await database;
//     return await db.update(
//       'documents',
//       document.toMap(),
//       where: 'id = ?',
//       whereArgs: [document.id],
//     );
//   }

//   // Search documents
//   Future<List<DocumentModel>> searchDocuments(String query) async {
//     Database db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'documents',
//       where: 'name LIKE ? OR description LIKE ? OR doctorName LIKE ?',
//       whereArgs: ['%$query%', '%$query%', '%$query%'],
//       orderBy: 'id DESC',
//     );
//     return List.generate(maps.length, (i) {
//       return DocumentModel.fromMap(maps[i]);
//     });
//   }

//   // Get documents count
//   Future<int> getDocumentsCount() async {
//     Database db = await database;
//     final count = Sqflite.firstIntValue(
//         await db.rawQuery('SELECT COUNT(*) FROM documents'));
//     return count ?? 0;
//   }

//   // Get documents by date range
//   Future<List<DocumentModel>> getDocumentsByDateRange(
//       String startDate, String endDate) async {
//     Database db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'documents',
//       where: 'date BETWEEN ? AND ?',
//       whereArgs: [startDate, endDate],
//       orderBy: 'date DESC',
//     );
//     return List.generate(maps.length, (i) {
//       return DocumentModel.fromMap(maps[i]);
//     });
//   }
// }