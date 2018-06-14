import 'dart:async';
import 'dart:io';
import 'package:delpack/cloud/FirestoreService.dart';
import 'package:delpack/loader.dart';
import 'package:flutter/services.dart';
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
import 'package:delpack/utils/Toast.dart';
import 'package:fluttertoast/fluttertoast.dart';


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
  bool loading = false;

  _CameraApp(dbManager,imageTextService) {
    this._dbManager = dbManager;
    this._imageTextService = imageTextService;
    _employeeDAO = EmployeeDAO(_dbManager);
    _vision = Vision();
  }

  Future _annotateImage() async {
    setState(() {
      loading = true;
      _deleteImageFile();
      _image = null;
    });

    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, maxWidth: 1200.0, maxHeight: 1200.0);
    if(image == null) {
      setState(() {
        loading = false;
        _deleteImageFile();
        _image = null;
      });
      return;
    }

    var bytes = image.readAsBytesSync();
    var annotations = await _vision.annotateImage(bytes);
    var candidates = _imageTextService.getNamesCandidates(annotations).map((c) => c.toLowerCase()).toSet();
    print(candidates);
    var filtered = _employees.where((e) => _employeeIsCandidate(e, candidates)).toList();
    _employee = filtered.isNotEmpty ? filtered[0] : null;
//    _employee = await _employeeDAO.getEmployee(candidates);
    if(_employee == null) {
      Fluttertoast.showToast(
          msg: 'Something went wrong please try again',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1
      );
    }

    setState(() {
      loading = false;
      _deleteImageFile();
      _image = image;
    });
  }

  bool _employeeIsCandidate(Employee e, Set<String> candidates) {
    var firstNameEn = e.firstNameEn?.trim()?.toLowerCase() ?? "";
    var lastNameEn = e.lastNameEn?.trim()?.toLowerCase() ?? "";
    var firstNameHe = e.firstNameHe?.trim()?.toLowerCase() ?? "";
    var lastNameHe = e.lastNameHe?.trim()?.toLowerCase() ?? "";

    return candidates.containsAll(firstNameEn.split(' ')) && candidates.containsAll(lastNameEn.split(' ')) ||
        candidates.containsAll(firstNameHe.split(' ')) && candidates.containsAll(lastNameHe.split(' '));
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
      if(!googleUser.email.toLowerCase().contains("outbrain")) {
        print("should be an Outbrain account!");
        _googleSignIn.signOut();
        return;
      }
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

  Future<Null> _handleSignOut() async {
    await _googleSignIn.signOut();
    await _googleSignIn.disconnect();
    ToastUtil.showToast('You Signed Out');
    setState(() {
      loading = false;
      _deleteImageFile();
      _image = null;
      _employee = null;
      _currentUser = null;
    });
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
//      _employee = _employee == null ? Employee(firstNameEn: 'firstname', lastNameEn: 'lastname', firstNameHe: 'fname_he', lastNameHe: 'lname_he', email: 'emaillonglong.email.com') : _employee;
      print(_employee);
      return Scaffold(
        appBar: AppBar(
          title: Text('Welcome ${_username == null ? "" : _username}'),
          actions: <Widget>[      // Add 3 lines from here...
            new IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _handleSignOut),
          ],                      // ... to here.
        ),
        body: Center(
          child: (_image == null || _employee == null) && loading ? new Loader() :
          _image == null || _employee == null ? Text('No image selected.')
              : EmployeeScreen(_employee, Image.file(_image), _image, _currentUser),
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
