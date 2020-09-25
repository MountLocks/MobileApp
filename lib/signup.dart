import 'package:flutter/material.dart';

import 'email_login.dart';
import 'email_signup.dart';

class SignUp extends StatelessWidget {
  final String title = "Sign Up";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(10.0),
                child: Image.asset(
                  'logo.png',
                  height: 100,
                  width: 100,
                )),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text("Mount Locks",
                  style: TextStyle(
                      fontSize: 30,
                      color: Color(0xff36424f),
                      fontFamily: 'Roboto')),
            ),
            ButtonTheme(
                minWidth: 200.0,
                height: 36.0,
                child: new RaisedButton(
                  child: new Text('Sign Up'),
                  color: Color(0xff36424f),
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmailSignUp()),
                    );
                  },
                )),
            ButtonTheme(
                minWidth: 200.0,
                height: 36.0,
                child: new OutlineButton(
                    child: new Text('Login'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmailLogIn()),
                      );
                    }))
          ]),
    ));
  }
}
