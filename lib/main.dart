import 'dart:async';
import 'dart:io';
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
  scopes: ['email'],
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

  _CameraApp(dbManager,imageTextService) {
    this._dbManager = dbManager;
    this._imageTextService = imageTextService;
    _employeeDAO = EmployeeDAO(_dbManager);
    _vision = Vision();
  }

  Future _annotateImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, maxWidth: 1200.0, maxHeight: 1200.0);
    if(image == null) {
      return;
    }
    var bytes = image.readAsBytesSync();
    var annotations = await _vision.annotateImage(bytes);
    var candidates = _imageTextService.getNamesCandidates(annotations);
    _employee = await _employeeDAO.getEmployee(candidates);
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
      print(_employee);
      return Scaffold(
        appBar: AppBar(
          title: Text('Welcome ${_username == null ? "" : _username}'),
        ),
        body: Center(
          child: _image == null || _employee == null
              ? Text('No image selected.')
              : EmployeeScreen(_employee, Image.file(_image)),
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
