import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class OfflineSyncService {
  OfflineSyncService._();

  static final OfflineSyncService instance = OfflineSyncService._();

  Database? _database;
  Future<void>? _initializing;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _syncing = false;

  Future<void> initialize() async {
    if (_database != null) return;
    if (_initializing != null) return _initializing!;
    _initializing = _openDatabase();
    await _initializing;
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen(
      (results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          unawaited(syncPending());
        }
      },
    );
    unawaited(syncPending());
  }

  Future<void> _openDatabase() async {
    final path = join(await getDatabasesPath(), 'resqnet_offline.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE pending_requests (id TEXT PRIMARY KEY, collection_name TEXT NOT NULL, payload TEXT NOT NULL, created_at TEXT NOT NULL)');
      },
    );
  }

  Future<bool> saveAndSync({
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    await initialize();
    final db = _database!;
    final id = 'offline_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
    final payload = jsonEncode(data);
    await db.insert('pending_requests', {
      'id': id,
      'collection_name': collectionName,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    });
    try {
      await _upload(id, collectionName, data);
      await db.delete('pending_requests', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncPending() async {
    if (_syncing || _database == null) return;
    _syncing = true;
    try {
      final rows = await _database!.query(
        'pending_requests',
        orderBy: 'created_at ASC',
      );
      for (final row in rows) {
        final id = row['id'] as String;
        final collection = row['collection_name'] as String;
        final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        try {
          await _upload(id, collection, payload);
          await _database!.delete('pending_requests', where: 'id = ?', whereArgs: [id]);
        } catch (_) {
          // Keep this record locally and retry on the next connectivity event.
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _upload(
    String id,
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    final converted = _convertTimestamps(data);
    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(id)
        .set(converted)
        .timeout(const Duration(seconds: 8));
  }

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if ((entry.key == 'createdAt' || entry.key == 'updatedAt') && value is String) {
        final date = DateTime.tryParse(value);
        result[entry.key] = date == null ? value : Timestamp.fromDate(date);
      } else if (value is Map) {
        result[entry.key] = _convertTimestamps(Map<String, dynamic>.from(value));
      } else if (value is List) {
        result[entry.key] = value.map((item) {
          if (item is Map) return _convertTimestamps(Map<String, dynamic>.from(item));
          return item;
        }).toList();
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }
}
