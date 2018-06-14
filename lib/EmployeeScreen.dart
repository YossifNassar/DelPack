import 'dart:convert';
import 'dart:io';
import 'package:delpack/common/GoogleHttpClient.dart';
import 'package:delpack/utils/Toast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'db/dao/EmployeeDAO.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

class EmployeeScreen extends StatelessWidget {
  final Employee _employee;
  final File _imageFile;
  final GoogleSignInAccount _currentUser;
  final Image _image;
  const EmployeeScreen(this._employee, this._image, this._imageFile, this._currentUser);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DefaultTextStyle(
            style: TextStyle(
                inherit: true,
                fontSize: 15.0,
                decorationStyle: TextDecorationStyle.wavy,
                color: Colors.black.withOpacity(0.8)),
            child: Container(
              decoration: BoxDecoration(color: Colors.white),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  new Image(image: this._image.image, width: 200.0),
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: new EdgeInsets.only(top: 20.0, left: 32.0),
                        child: Row(
                          children: <Widget>[
                            new Text('Deliver To:',
                                style: new TextStyle(color: Colors.blueGrey)),
                            Padding(
                                padding: new EdgeInsets.only(left: 10.0),
                                child: new Text(
                                    '${_employee.firstNameEn} ${_employee
                                        .lastNameEn}'))
                          ],
                        ),
                      ),
                      Padding(
                          padding: new EdgeInsets.only(top: 3.0, left: 32.0),
                          child: Row(
                            children: <Widget>[
                              new Text('Email:',
                                  style: new TextStyle(color: Colors.blueGrey)),
                              Padding(
                                  padding: new EdgeInsets.only(left: 10.0),
                                  child: new Text('${_employee.email}')
                              )

                            ],
                          ))
                    ],
                  ),
                  Padding(
                      padding: new EdgeInsets.only(top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new RaisedButton(
                            onPressed: () {
                              notifyUser(Delivery.deliver);
                            },
                            child: new Text('Deliver'),
                            color: Colors.blueGrey,
                            textColor: Colors.white
                          ),
                          new RaisedButton(
                              onPressed: () {
                                notifyUser(Delivery.notify);
                              },
                              child: new Text('Notify'),
                              color: Colors.blueGrey,
                              textColor: Colors.white)
                        ],
                      ))
                ],
              ),
            )));
  }

  void notifyUser(Delivery type) {
    handleEmailNotification(type);
  }

  void handleEmailNotification(Delivery type) async {
    var authHeaders = await _currentUser.authHeaders;
    var httpClient = new GoogleHttpClient(authHeaders);
    var gmailClient = new GmailApi(httpClient);


    List<int> imageBytes = _imageFile.readAsBytesSync();
    String base64Image = BASE64.encode(imageBytes);

    var from = _currentUser.email;
    var to = _employee.email;
    var notifier = _currentUser.displayName;
    var subject = 'Delpack ' + (type == Delivery.notify ? "You have got a package, Notified by: $notifier" : "I'll bring you the package, Notified by: $notifier");
    var message = base64Image;
    var content = '''
Content-Type: image/bmp"
MIME-Version: 1.0
Content-Transfer-Encoding: base64
to: $to
from: $from
subject: $subject

$message''';

    var bytes = utf8.encode(content);
    var base64 = base64Encode(bytes);
    Message msg = new Message()
    ..raw = base64;
    print( '_currentUser ${_currentUser.email} ${_currentUser.authentication}');


    try {
      await gmailClient.users.messages.send(msg, _currentUser.email);
      ToastUtil.showToast('Message sent');
    } catch(e) {
      ToastUtil.showToast('An error accure');
    }
  }
}

enum Delivery{
  deliver, notify
}

