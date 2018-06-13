import 'dart:io';
import 'dart:core';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseManager {
  Database _db;

  DatabaseManager() {
    _initDB();
  }

  Database getDatabase() {
    return _db;
  }

  void dispose() {
    _db.close();
  }

  void _initDB() async{
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = "${documentsDirectory.path}/demo.db";
    print(path);
//  await deleteDatabase(path);
    _db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          // When creating the db, create the table
          await db.execute(
              "CREATE TABLE Test (id INTEGER PRIMARY KEY, fname_en TEXT, lname_en TEXT, fname_he TEXT, lname_he TEXT, email TEXT)");
        });
  }
}