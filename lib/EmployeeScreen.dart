import 'db/dao/EmployeeDAO.dart';
import 'package:flutter/material.dart';

class EmployeeScreen extends StatelessWidget {
  final Employee _employee;
  final Image _imageFile;

  const EmployeeScreen(this._employee, this._imageFile);

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
                  new Image(image: this._imageFile.image, width: 200.0),
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: new EdgeInsets.only(top: 20.0, left: 32.0),
                        child: Row(
                          children: <Widget>[
                            new Text('Deliver To:',
                                style: new TextStyle(color: Colors.blue)),
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
                                  style: new TextStyle(color: Colors.blue)),
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
                              notifyUser();
                            },
                            child: new Text('Deliver'),
                            color: Colors.blue,
                            textColor: Colors.white
                          ),
                          new RaisedButton(
                              onPressed: () {
                                notifyUser();
                              },
                              child: new Text('Notify'),
                              color: Colors.blue,
                              textColor: Colors.white)
                        ],
                      ))
                ],
              ),
            )));
  }

  void notifyUser() {
    print('notify');
    return;
  }
}

class EmployeeData extends StatelessWidget {
  final Employee _employee;

  const EmployeeData(this._employee);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[new Text(this._employee.firstNameEn)],
    );
  }
}
