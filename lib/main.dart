import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:firebase_auth/firebase_auth.dart';
import "package:googleapis_auth/auth_io.dart";
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

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

  runApp(new MaterialApp(
    title: 'DelPack',
    home: new FirstScreen(user.displayName),
    theme: new ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      accentColor: Colors.blueGrey,
    ),
  ));
}

class FirstScreen extends StatelessWidget {
  final String _loggedUser;

  FirstScreen(String loggedUser):
        _loggedUser = loggedUser;

  @override
  Widget build(BuildContext context) {
    return new CameraApp(_loggedUser);
  }
}

class CameraApp extends StatefulWidget {
  final String _username;

  CameraApp(String username):
    _username = username;


  @override
  _CameraApp createState() => new _CameraApp(_username);
}

class _CameraApp extends State<CameraApp> {
  final String _username;
  vision.VisionApi _visionApi;

  _CameraApp(String username):
        _username = username;

  File _image;

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera, maxWidth: 1200.0, maxHeight: 1200.0);
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

  Future<String> _getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  void _initVision() async{
    String keyTxt = await _getFileData("text/cloudsecret.json");
    final accountCredentials = new ServiceAccountCredentials.fromJson(json.decode(keyTxt));
    var scopes = ['https://www.googleapis.com/auth/cloud-vision'];
    AuthClient client;
    client = await clientViaServiceAccount(accountCredentials, scopes)
        .then((AuthClient client) {
      // [client] is an authenticated HTTP client.
      return client;
    });

    print("client: $client");
    _visionApi = vision.VisionApi(client);
  }

  @override
  void initState() {
    _initVision();
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
