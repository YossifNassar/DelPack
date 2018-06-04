import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn;
import 'package:firebase_auth/firebase_auth.dart';
import "package:googleapis_auth/auth_io.dart";
import 'package:image_picker/image_picker.dart';

List<CameraDescription> cameras;
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
  cameras = await availableCameras();

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

  final accountCredentials = new ServiceAccountCredentials.fromJson({
    "type": "service_account",
    "project_id": "delpack-206016",
    "private_key_id": "7b197b039db3b5000ca1553a0997d2a1b9896518",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCDoaK3RAMBhhVD\ndV7kJYRRzsZOw3sDdQmF3jWtrffIOxQM5begJDCUFZBn6IOQq4rKm70U0WxTWjg/\n0XxiGTzsMQ4Emk5SrBXVowNEOJ/t5P5f04RwsVa9iMJpz1yR9r9rCrRVJb/+l52e\nZpAf0cTBJv4G5TQRICb28SMk3COrU/JSS0M46Sx8IGHX2NypLibeMJjfKKt8HAfk\nkdngz2Z3MvHuNuRAtKhttApQvivn3gMqzNLTUUmnDZO7pplgOIExKkEzCadoU5L2\nbdCNU0uAPgQTMACCkEA6XzTxwXUbPvx5l4GcSjfio+LfsqPs99B3URiHgoo8lPW/\nliSXymNlAgMBAAECggEAAzUs5WauXBJYrYHDyBWnTKCpWDj1bJl6E0P/zHnXfyhR\nZ7NSd5EdZ4s5prlAW4Xn+67uTGToxHwHsDeC76iFyjZeN8AYwqhTtCe+rF3cWxCP\nHyptdfCCy9KN4+a+RBfNYuaqR2n70vtkvtnX7QPqCOFapDQb0xzheFXBE6BXlrcU\nTvRPLsfLuonI4llHQviK5h6Le7yNylILJunNHKlMhxd0AhtoJwSN7+Kkitb8prcb\ncohP3Xsx5hDvOBSaCyobCM+RZz48WktfZ70Vv0iKRm76X7xmR88Wdgp57tDcc6y7\nXkythntCwRGHWXgJMwwM56FLMoBwyknt2UkWFZYwkQKBgQC5Nu2OsN7pS1HO1rKy\nbfmHjnUn0D9k4zeu/OE1nr17pVRTUMNT6Plb4wCZ8ZmDBid4scejNZYT08EFEm4n\niTHqh3sbqCmPDSorBB+CBPdxAxX3c/Usx1m+13lduEHtBap0ZQJ+11cxHZKD/UnH\niyWMKFGQ6ek53ogmo4cW8FlGwwKBgQC18DkHhGZGaDfntCkc2tjONBnoYO7YJ01k\na8pTzUnvtzMkf7WKvTkohdIPs4MJbSSwrjDfLof5DbRvdybrs2UsOvweFOoItkCv\npObL7icc3Y8xHmEPU8Orm8T5V3wZ4x9OnYed8LjznCiDooTQ3BXlrfeYnkFfZ1E4\nxeJxa4MatwKBgQCdWhsMxRs8XG8OKLz8dg4uqkrCHlwdXCSsl87FfS1B5L31YoHv\nwdhHxl12bBmdhRb3pSIUeKweACLWKkhHcnlj5OIkJwPXsrmGfiQ+k/Wcn6CD8JH1\nDxAh4HINu0LXGZ8s77vlAxHieltFo2SREJg/sOlLEk7AiVxmZzuXs25FfQKBgQCo\nxXCBsqYVRfQmMg+5PqHDlr05vUGSrdKzBvKnDlY50p3Ui8tiKent10VnX0R86AwT\nAWNAhS+JLtdkVwl5t+5wOz9IwGnhLv+Ob8/Q+Ni7hCOikuXCjBeFB3iPPEJY2UFf\nce4t6vIGuaMziPzfqml9qAV4Q8WstHC504cdY3g4vQKBgEdTvIblISC7jO/07ZT2\nWgRa3b+nlP//XJcqzqYM3TK7cqMB4EShlPHZDfkU3LzUMg/mUEtv/YYR350vQ+mr\noHIqL7YdZ6e0NIx0SbQavylVIsK23G9iLR2x/K7ZrEhthOfz7JDSSPw748Wt66y5\nTI00Ad0Ywjw0RkYUIa5R6cqN\n-----END PRIVATE KEY-----\n",
    "client_email":
        "delpack-service-account@delpack-206016.iam.gserviceaccount.com",
    "client_id": "114220544307704907188",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://accounts.google.com/o/oauth2/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/delpack-service-account%40delpack-206016.iam.gserviceaccount.com"
  });
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
    home: new FirstScreen("User: ${user.displayName}"),
  ));
}

class FirstScreen extends StatelessWidget {
  String _loggedUser;

  FirstScreen(String loggedUser) {
    this._loggedUser = loggedUser;
  }

  @override
  Widget build(BuildContext context) {
    return new CameraApp();
  }
}

class CameraApp extends StatefulWidget {
  @override
  _CameraApp createState() => new _CameraApp();
}

class _CameraApp extends State<CameraApp> {
  File _image;

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
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
        title: new Text('Image Picker Example'),
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
