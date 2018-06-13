import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  final Function _handleSignIn;

  const SignInScreen(this._handleSignIn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.all(32.0),
      child: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Please sign in with your Outbrain account',
                style: TextStyle(
                  color: Colors.black,
                  letterSpacing: 0.5,
                  fontSize: 20.0,
                ),
              )),
          RaisedButton(child: const Text("Sign In"), onPressed: _handleSignIn)
        ],
      )),
    ));
  }
}
