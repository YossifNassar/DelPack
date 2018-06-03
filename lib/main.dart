import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignIn;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle,ByteData;
import 'imagescreen.dart';
import "package:googleapis_auth/auth_io.dart";

List<CameraDescription> cameras;
vision.VisionApi visionApi;
AuthClient client;

Future<ByteData> _getImageBytes(String image) async{
  return await rootBundle.load(image);
}

Future<Null> _annotateImage(String filePath) async {
  var bytes = await _getImageBytes(filePath);
  var imp = visionApi.images;
  var request = vision.AnnotateImageRequest()
    ..features = [vision.Feature()..type = "DOCUMENT_TEXT_DETECTION"];
  var image = vision.Image()
    ..contentAsBytes = bytes.buffer.asUint8List().cast();
  request.image = image;
  var annotateRequest = vision.BatchAnnotateImagesRequest()
    ..requests = [request];
  var res = await imp.annotate(annotateRequest);
  res?.responses?.forEach((r) {
    r.textAnnotations.forEach((txt) {
      print(txt.description);
    });
  });

}

Future<Null> main() async {
  cameras = await availableCameras();

  final _googleSignIn = new GoogleSignIn(
    scopes: [
      'email'
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var googleUser = await _googleSignIn.signIn();
  var googleAuth = await googleUser.authentication;
  var user = await _auth.signInWithGoogle(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  print("signed in ${user.displayName}");


  final accountCredentials = new ServiceAccountCredentials.fromJson({
    //JSON
  });
  var scopes =  [
      'https://www.googleapis.com/auth/cloud-vision'
    ];

  var prompt = (String url) {
    print("Please go to the following URL and grant access:");
    print("  => $url");
    print("");
  };

  client = await clientViaServiceAccount(accountCredentials, scopes).then((AuthClient client) {
    // [client] is an authenticated HTTP client.
    return client;
  });

  print("client: $client");
  visionApi = vision.VisionApi(client);

  runApp(new MaterialApp(
    title: 'FoodyV',
    home: new FirstScreen("User: none"),
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
  String loggedUser;
  CameraApp(String loggedUser) {
    this.loggedUser = loggedUser;
  }

  @override
  _CameraAppState createState() => new _CameraAppState(loggedUser);
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  String _filePath;
  String loggedUser;

  _CameraAppState(String loggedUser) {
    this.loggedUser = loggedUser;
  }

  void _showCameraException(CameraException e) {
    print("${e.code}, ${e.description}");
  }

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void takePicture() async {
    if (!controller.value.isInitialized) {
      print('Error: select a camera first.');
      return;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return;
    }
    File file = new File(filePath);
    if(file.existsSync()) {
      file.deleteSync();
    }
    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }

    _filePath = filePath;
    _navigateToImageScreen();
    _annotateImage(_filePath);
  }

  Widget _cameraFloatingWidget() {
    return new Align(
        alignment: Alignment.bottomRight,
        child: new FloatingActionButton(
          onPressed: takePicture,
          tooltip: "take a shot",
          child: new Icon(Icons.photo_camera, size: 30.0),
        ));
  }

  void _navigateToImageScreen(){
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new ImageScreen(filePath: _filePath)),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = new CameraController(cameras[0], ResolutionPreset.low);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return new Container();
    }
    return
      new Scaffold(
        appBar: new AppBar(
          title: new Text("$loggedUser"),
        ),
        body: new Center(
          child: new CameraPreview(controller),
        ),
        floatingActionButton: _cameraFloatingWidget(),
      );
  }
}
