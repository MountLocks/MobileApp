import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'signup.dart';

void main() => runApp(MyApp());

const PrimaryColor = const Color(0xFF36424f);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mount',
      theme: ThemeData(
        primaryColor: Color(0xff36424f),
      ),
      home: IntroScreen(),
    );
  }
}

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser().then((res) {
      print(res);
      if (res != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home(uid: res.uid)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignUp()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new SignUp();
  }
}
