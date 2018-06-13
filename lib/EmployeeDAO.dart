import 'dart:async';
import 'package:sqflite/sqflite.dart';

void handleDB() async {
//  // Get a location using path_provider
//  Directory documentsDirectory = await getApplicationDocumentsDirectory();
//  String path = "${documentsDirectory.path}/demo.db";
//// Delete the database
//  await deleteDatabase(path);
//// open the database
//  Database database = await openDatabase(path, version: 1,
//      onCreate: (Database db, int version) async {
//        // When creating the db, create the table
//        await db.execute(
//            "CREATE TABLE Test (id INTEGER PRIMARY KEY, fname_en TEXT, lname_en TEXT, fname_he TEXT, lname_he TEXT, email TEXT)");
//      });
//  // Insert some records in a transaction
//
//  var query = buildSearchQuery(['יוסף', 'נסאר‎']);
//  print(query);
//  List<Map> list = await database.rawQuery(query);
//  print(list);
//// Close the database
//  await database.close();
}

class EmployeeDAO {
  final Database _database;

  const EmployeeDAO(this._database);

  Future<Null> insertEmployee(Employee employee) async {
    await _database.transaction((txn) async {
      int id1 = await txn.rawInsert(
          "INSERT INTO Test(fname_en, lname_en, fname_he, lname_he, email) VALUES('${employee
              .firstNameEn}', '${employee.lastNameEn}', '${employee
              .firstNameHe}', '${employee.lastNameHe}', '${employee.email}')");
      print("inserted1: $id1");
    });
  }

  Future<List<Employee>> getEmployees(List<String> names) async {
    var query = _buildSearchQuery(names);
    print(query);
    List<Map> list = await _database.rawQuery(query);
    print(list);
    return list
        .map((map) => Employee(map['fname_en'], map['lname_eng'],
            map['fname_he'], map['lname_he'], map['email']))
        .toList();
  }

  void dispose() {
    _database.close();
  }

  String _buildSearchQuery(List<String> words) {
    var base = "SELECT * FROM Test";
    if (words.isEmpty) {
      return base;
    }
    var quoted = words.map((word) => "'$word'").toList();
    var conditions = List<String>();
    conditions.add("where fname_en = ${quoted.join(" OR fname_en = ")}");
    conditions.add("lname_en = ${quoted.join(" OR lname_en = ")}");
    conditions.add("fname_he = ${quoted.join(" OR fname_he = ")}");
    conditions.add("lname_he = ${quoted.join(" OR lname_he = ")}");
    return "$base ${conditions.join(" OR ")}";
  }
}

class Employee {
  String firstNameEn;
  String lastNameEn;
  String firstNameHe;
  String lastNameHe;
  String email;

  Employee(String firstNameEn, String lastNameEn, String firstNameHe,
      String lastNameHe, String email) {
    this.firstNameEn = firstNameEn;
    this.lastNameEn = lastNameEn;
    this.firstNameHe = firstNameHe;
    this.lastNameHe = lastNameHe;
    this.email = email;
  }

  @override
  String toString() {
    return "{firstNameEn: $firstNameEn, lastNameEn: $lastNameEn, firstNameHe: $firstNameHe, lastNameHe: $lastNameHe, email: $email}";
  }
}
