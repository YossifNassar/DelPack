import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:firebase_auth/firebase_auth.dart';
import "package:googleapis_auth/auth_io.dart";
import 'package:image_picker/image_picker.dart';

vision.VisionApi visionApi;
AuthClient client;

Future<Null> _annotateImage(List<int> bytes) async {
  var imp = visionApi.images;
  var request = vision.AnnotateImageRequest()
    ..features = [vision.Feature()..type = "DOCUMENT_TEXT_DETECTION"];
//  var imageSource = vision.ImageSource()
//    ..imageUri = "https://cloud.google.com/vision/docs/images/abbey_road.JPG";
  var image = vision.Image()
//    ..source = imageSource;
    ..contentAsBytes = bytes;
  request.image = image;
  var annotateRequest = vision.BatchAnnotateImagesRequest()
    ..requests = [request];
  print("Sending request at: ${DateTime.now()}");
  var res = await imp.annotate(annotateRequest);
  print("Receiving response at: ${DateTime.now()}");
  res?.responses?.forEach((r) {
    r.textAnnotations.forEach((txt) {
      print(txt.description);
    });
  });
  print("Done printing annotations at: ${DateTime.now()}");
}

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
      { //JSON
      }
  );
  var scopes = ['https://www.googleapis.com/auth/cloud-vision'];

  client = await clientViaServiceAccount(accountCredentials, scopes)
      .then((AuthClient client) {
    // [client] is an authenticated HTTP client.
    return client;
  });

  print("client: $client");
  visionApi = vision.VisionApi(client);

  runApp(new MaterialApp(
    title: 'DelPack',
    home: new FirstScreen(user.displayName),
  ));
}

class FirstScreen extends StatelessWidget {
  String _loggedUser;

  FirstScreen(String loggedUser) {
    this._loggedUser = loggedUser;
  }

  @override
  Widget build(BuildContext context) {
    return new CameraApp(_loggedUser);
  }
}

class CameraApp extends StatefulWidget {
  String _username;
  CameraApp(String username) {
    this._username = username;
  }

  @override
  _CameraApp createState() => new _CameraApp(_username);
}

class _CameraApp extends State<CameraApp> {
  String _username;
  _CameraApp(String username) {
    this._username = username;
  }

  File _image;

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera, maxHeight: 1500.0, maxWidth: 1500.0);
    var bytes = image.readAsBytesSync();
    _annotateImage(bytes);

    setState(() {
      _image = image;
    });
  }

  @override
  void initState() {
    super.initState();
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
