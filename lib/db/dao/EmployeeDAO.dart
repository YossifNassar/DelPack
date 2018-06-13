import 'dart:async';
import 'package:delpack/common/utils.dart';
import '../DatabaseManager.dart';

class EmployeeDAO {
  final DatabaseManager _dbManager;

  const EmployeeDAO(this._dbManager);

  Future<Null> insertEmployee(Employee employee) async {
    await _dbManager.getDatabase().transaction((txn) async {
      int id1 = await txn.rawInsert(
          "INSERT INTO Test(fname_en, lname_en, fname_he, lname_he, email) VALUES('${employee
              .firstNameEn}', '${employee.lastNameEn}', '${employee
              .firstNameHe}', '${employee.lastNameHe}', '${employee.email}')");
      print("inserted1: $id1");
    });
  }

  Future<Employee> getEmployee(Set<String> candidates) async {
    var _candidates = candidates.map((c) => c.toLowerCase()).toSet();
    print(_candidates);
    var candidatesGroups = toGroup(_candidates,5);
    var result = List<Employee>();
    for(var group in candidatesGroups) {
      print(group);
      var query = _buildSearchQuery(group);
      print(query);
      List<Map> list = await _dbManager.getDatabase().rawQuery(query);
      print(list);
      result.addAll( list
          .map((map) => Employee.fromMap(map))
          .toList()
      );
    }
    var filtered = result.where((e) => _candidates.contains(e.firstNameEn) && _candidates.contains(e.lastNameEn) || _candidates.contains(e.firstNameHe) && _candidates.contains(e.lastNameHe)).toList();
    return filtered.isNotEmpty ? filtered[0] : null;
  }

  String _buildSearchQuery(Set<String> words) {
    var base = "SELECT * FROM Test";
    if (words.isEmpty) {
      return base;
    }
    var quoted = words.map((word) => "'${word.toLowerCase()}'").toList();
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

  Employee({String firstNameEn, String lastNameEn, String firstNameHe,
      String lastNameHe, String email}) {
    this.firstNameEn = firstNameEn;
    this.lastNameEn = lastNameEn;
    this.firstNameHe = firstNameHe;
    this.lastNameHe = lastNameHe;
    this.email = email;
  }

  Employee.fromMap(Map<String,dynamic> map) : this(firstNameEn: map['fname_en'], lastNameEn: map['lname_en'],
      firstNameHe: map['fname_he'], lastNameHe: map['lname_he'], email: map['email']);


  @override
  String toString() {
    return "{firstNameEn: $firstNameEn, lastNameEn: $lastNameEn, firstNameHe: $firstNameHe, lastNameHe: $lastNameHe, email: $email}";
  }
}
