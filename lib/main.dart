import 'dart:async';
import 'dart:io';
import 'package:delpack/GoogleHttpClient.dart';
import 'package:delpack/cloud/FirestoreService.dart';
import 'package:googleapis/gmail/v1.dart';
import 'cloud/Vision.dart';
import 'image/textService/ImageTextService.dart';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'SignInScreen.dart';
import 'db/dao/EmployeeDAO.dart';
import 'db/DatabaseManager.dart';
import 'EmployeeScreen.dart';


final _googleSignIn = GoogleSignIn(
  scopes: ['email','https://www.googleapis.com/auth/gmail.compose'],
);

void main() {
  final dbManager = DatabaseManager();
  final imageTextService = ImageTextService();

  runApp(MaterialApp(
    title: 'DelPack',
    home: FirstScreen(dbManager,imageTextService),
    theme: ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      accentColor: Colors.blueGrey,
    ),
  ));
}

class FirstScreen extends StatelessWidget {
  final DatabaseManager _dbManager;
  final ImageTextService _imageTextService;
  const FirstScreen(this._dbManager,this._imageTextService);

  @override
  Widget build(BuildContext context) {
    return CameraApp(this._dbManager,this._imageTextService);
  }
}

class CameraApp extends StatefulWidget {
  final DatabaseManager _dbManager;
  final ImageTextService _imageTextService;
  const CameraApp(this._dbManager,this._imageTextService);

  @override
  _CameraApp createState() => _CameraApp(this._dbManager,this._imageTextService);
}

class _CameraApp extends State<CameraApp> {
  GoogleSignInAccount _currentUser;
  String _username;
  File _image;
  EmployeeDAO _employeeDAO;
  Employee _employee;
  DatabaseManager _dbManager;
  ImageTextService _imageTextService;
  Vision _vision;
  List<Employee> _employees;

  _CameraApp(dbManager,imageTextService) {
    this._dbManager = dbManager;
    this._imageTextService = imageTextService;
    _employeeDAO = EmployeeDAO(_dbManager);
    _vision = Vision();
//    _dbManager.insertEmployee(Employee.fromMap({"lname_en": "nassar", "fname_he": "sdgs", "lname_he": "sdgfsdg", "fname_en": "yossif", "email": "ynassar@outbrain.com" }));
  }

  Future _annotateImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, maxWidth: 1200.0, maxHeight: 1200.0);
    if(image == null) {
      return;
    }
    var bytes = image.readAsBytesSync();
    var annotations = await _vision.annotateImage(bytes);
    var candidates = _imageTextService.getNamesCandidates(annotations).map((c) => c.toLowerCase()).toSet();
    print(candidates);
    print(_employees);
    var filtered = _employees.where((e) => candidates.contains(e.firstNameEn) && candidates.contains(e.lastNameEn) || candidates.contains(e.firstNameHe) && candidates.contains(e.lastNameHe)).toList();
    _employee = filtered.isNotEmpty ? filtered[0] : null;
//    _employee = await _employeeDAO.getEmployee(candidates);
    print("Found employee: $_employee");

    setState(() {
      _deleteImageFile();
      _image = image;
    });
  }

  void _deleteImageFile() {
    if (_image != null) {
      _image.delete();
      _image = null;
    }
  }

  Future<Null> _handleSignIn() async {
    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      var googleUser = await _googleSignIn.signIn();
//      if(!googleUser.email.toLowerCase().contains("outbrain")) {
//        print("should be an Outbrain account!");
//        _googleSignIn.signOut();
//        return;
//      }
      var googleAuth = await googleUser.authentication;
      var firebaseUser = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      setState(() {
        _username = firebaseUser.displayName;
      });
    } catch (error) {
      print(error);
    }
  }

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
    _handleSignIn();
    employeesCollection.snapshots().forEach((snapshot) async {
      _employees = new List<Employee>();
      snapshot.documents.forEach((doc){
        print(doc.data);
        print(Employee.fromMap(doc.data));
//        _employeeDAO.insertEmployee(Employee.fromMap(doc.data));
        _employees.add(Employee.fromMap(doc.data));
      });
    });
  }

  @override
  void dispose() {
    _deleteImageFile();
    _dbManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser != null) {
      _employee = _employee == null ? Employee(firstNameEn: 'firstname', lastNameEn: 'lastname', firstNameHe: 'fname_he', lastNameHe: 'lname_he', email: 'emaillonglong.email.com') : _employee;
      print(_employee);
      return Scaffold(
        appBar: AppBar(
          title: Text('Welcome ${_username == null ? "" : _username}'),
        ),
        body: Center(
          child: _image == null || _employee == null
              ? Text('No image selected.')
              : EmployeeScreen(_employee, Image.file(_image), _currentUser),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _annotateImage,
          tooltip: 'Pick Image',
          child: Icon(Icons.add_a_photo),
        ),
      );
    } else {
      return SignInScreen(_handleSignIn);
    }
  }
}
