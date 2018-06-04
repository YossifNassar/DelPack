import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:firebase_auth/firebase_auth.dart';
import "package:googleapis_auth/auth_io.dart";
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';

Future<Null> main() async {
  final _googleSignIn = new GoogleSignIn(
    scopes: ['email'],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var googleUser = await _googleSignIn.signIn();
  var googleAuth = await googleUser.authentication;
  var user = await _auth.signInWithGoogle(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  print("signed in ${user.displayName}");

  final accountCredentials = new ServiceAccountCredentials.fromJson(
  {
    //JSON
  }
  );
  var scopes = ['https://www.googleapis.com/auth/cloud-vision'];
  vision.VisionApi visionApi;
  AuthClient client;
  client = await clientViaServiceAccount(accountCredentials, scopes)
      .then((AuthClient client) {
    // [client] is an authenticated HTTP client.
    return client;
  });

  print("client: $client");
  visionApi = vision.VisionApi(client);

  runApp(new MaterialApp(
    title: 'DelPack',
    home: new FirstScreen(user.displayName, visionApi),
    theme: new ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      accentColor: Colors.blueGrey,
    ),
  ));
}

class FirstScreen extends StatelessWidget {
  final String _loggedUser;
  final vision.VisionApi _visionApi;

  FirstScreen(String loggedUser, vision.VisionApi visionApi):
        _loggedUser = loggedUser, _visionApi = visionApi;

  @override
  Widget build(BuildContext context) {
    return new CameraApp(_loggedUser, _visionApi);
  }
}

class CameraApp extends StatefulWidget {
  final String _username;
  final vision.VisionApi _visionApi;

  CameraApp(String username, vision.VisionApi visionApi):
    _username = username, _visionApi = visionApi;


  @override
  _CameraApp createState() => new _CameraApp(_username, _visionApi);
}

class _CameraApp extends State<CameraApp> {
  final String _username;
  final vision.VisionApi _visionApi;

  _CameraApp(String username, vision.VisionApi visionApi):
        _username = username, _visionApi = visionApi;

  File _image;

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera, maxHeight: 1250.0, maxWidth: 1000.0);
    var bytes = image.readAsBytesSync();
    _annotateImage(bytes);

    setState(() {
      _deleteImageFile();
      _image = image;
    });
  }

  Future<Null> _annotateImage(List<int> bytes) async {
    var imp = _visionApi.images;
    var request = vision.AnnotateImageRequest()
      ..features = [vision.Feature()..type = "DOCUMENT_TEXT_DETECTION"];
    var image = vision.Image()
      ..contentAsBytes = bytes;
    request.image = image;
    var annotateRequest = vision.BatchAnnotateImagesRequest()
      ..requests = [request];
    print("Request was sent at: ${DateTime.now()}");
    var res = await imp.annotate(annotateRequest);
    print("Response was received at: ${DateTime.now()}");
    res?.responses?.forEach((r) {
      r.textAnnotations.forEach((txt) {
        print(txt.description);
      });
    });
  }

  void _deleteImageFile() {
    if(_image != null) {
      _image.delete();
      _image = null;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _deleteImageFile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Welcome $_username'),
      ),
      body: new Center(
        child: _image == null
            ? new Text('No image selected.')
            : new Image.file(_image),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: new Icon(Icons.add_a_photo),
      ),
    );
  }
}
