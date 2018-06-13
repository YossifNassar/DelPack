import 'db/dao/EmployeeDAO.dart';
import 'package:flutter/material.dart';

class EmployeeScreen extends StatelessWidget {
  final Employee _employee;
  final Image _imageFile;

  const EmployeeScreen(this._employee, this._imageFile);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Row(
            children: <Widget>[
              new Image(image: this._imageFile.image, width: 100.0),
              Row(
                children: <Widget>[
                  new Text('Deliver To:'),
                  new Text('${_employee.firstNameEn} ${_employee.lastNameEn}')
                ],
              )
            ],
          ),
          Row(
            children: <Widget>[
              new RaisedButton(onPressed: () {notifyUser();}, child: new Text('Deliver'),),
              new RaisedButton(onPressed: () {notifyUser();}, child: new Text('Notify'))
            ],
          )
        ],
      ),
    ));
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
