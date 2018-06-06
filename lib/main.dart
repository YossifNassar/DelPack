import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:firebase_auth/firebase_auth.dart';
import "package:googleapis_auth/auth_io.dart";
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert' show json;
import 'package:google_sign_in/google_sign_in.dart';
import 'logInScreen.dart';

final _googleSignIn = GoogleSignIn(
  scopes: ['email'],
);

Future<Null> main() async {
  runApp(MaterialApp(
    title: 'DelPack',
    home: FirstScreen(),
    theme: ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      accentColor: Colors.blueGrey,
    ),
  ));
}

class FirstScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CameraApp();
  }
}

class CameraApp extends StatefulWidget {
  @override
  _CameraApp createState() => _CameraApp();
}

class _CameraApp extends State<CameraApp> {
  GoogleSignInAccount _currentUser;
  String _username;
  vision.VisionApi _visionApi;
  File _image;

  Future getImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, maxWidth: 1200.0, maxHeight: 1200.0);
    var bytes = image.readAsBytesSync();
    _annotateImage(bytes);

    setState(() {
      _deleteImageFile();
      _image = image;
    });
  }

  Future<Null> _annotateImage(List<int> bytes) async {
    var imp = _visionApi.images;
    var image = vision.Image()..contentAsBytes = bytes;
    var request = vision.AnnotateImageRequest()
      ..features = [vision.Feature()..type = "DOCUMENT_TEXT_DETECTION"]
      ..image = image;
    var annotateRequests = vision.BatchAnnotateImagesRequest()
      ..requests = [request];
    print("Request was sent at: ${DateTime.now()}");
    var res = await imp.annotate(annotateRequests);
    print("Response was received at: ${DateTime.now()}");
    res?.responses?.forEach((r) {
      r.textAnnotations.forEach((txt) {
        print(txt.description);
      });
    });
  }

  void _deleteImageFile() {
    if (_image != null) {
      _image.delete();
      _image = null;
    }
  }

  Future<String> _getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  void _initVision() async {
    String keyTxt = await _getFileData("text/cloudsecret.json");
    final accountCredentials = ServiceAccountCredentials.fromJson(json.decode(keyTxt));
    var scopes = ['https://www.googleapis.com/auth/cloud-vision'];
    AuthClient client = await clientViaServiceAccount(accountCredentials, scopes)
        .then((AuthClient client) {
      // [client] is an authenticated HTTP client.
      return client;
    });

    print("client: $client");
    _visionApi = vision.VisionApi(client);
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
      if (_currentUser != null) {
        _initVision();
      }
    });
    _googleSignIn.signInSilently();
  }

  @override
  void dispose() {
    _deleteImageFile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Welcome ${_username == null ? "" : _username}'),
        ),
        body: Center(
          child: _image == null
              ? Text('No image selected.')
              : Image.file(_image),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: getImage,
          tooltip: 'Pick Image',
          child: Icon(Icons.add_a_photo),
        ),
      );
    } else {
      return SignInScreen(_handleSignIn);
    }
  }
}
