import 'dart:async';
import 'dart:core';
import 'package:googleapis/vision/v1.dart' as vision;
import "package:googleapis_auth/auth_io.dart";
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert' show json;

class Vision {
  vision.VisionApi _visionApi;

  Vision() {
    _initVision();
  }

  Future<List<vision.EntityAnnotation>> annotateImage(List<int> bytes) async {
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
    var annotations = List<vision.EntityAnnotation>();
    res?.responses?.forEach((r) {
      annotations.addAll(r.textAnnotations);
      r.textAnnotations.forEach((ann) => print(ann.description));
    });
    return annotations;
  }

  void _initVision() async {
    String keyTxt = await _getFileData("text/cloudsecret.json");
    final accountCredentials =
        ServiceAccountCredentials.fromJson(json.decode(keyTxt));
    var scopes = ['https://www.googleapis.com/auth/cloud-vision'];
    AuthClient client =
        await clientViaServiceAccount(accountCredentials, scopes)
            .then((AuthClient client) {
      // [client] is an authenticated HTTP client.
      return client;
    });

    print("client: $client");
    _visionApi = vision.VisionApi(client);
  }

  Future<String> _getFileData(String path) async {
    return await rootBundle.loadString(path);
  }
}
