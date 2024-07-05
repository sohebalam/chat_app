import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chat_app/screens/auth/register_screen.dart';
import 'package:chat_app/screens/chat/chat_list.dart';
import 'package:chat_app/shared/auth_service.dart';
import 'package:chat_app/shared/style/contstants.dart';
import 'package:chat_app/shared/widgets/app_bar.dart';

class AuthScreen extends StatefulWidget {
  final DateTime? startdatetime;
  final DateTime? enddatetime;
  final String? cpsId;
  final String? routePage;
  final String? address;
  final String? image;
  final String? postcode;
  final String? u_id;

  const AuthScreen({
    super.key,
    this.startdatetime,
    this.enddatetime,
    this.cpsId,
    this.routePage,
    this.address,
    this.image,
    this.postcode,
    this.u_id,
  });

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscureText = true;
  String _errorMessage = '';
  bool redirectToChat = false;

  @override
  void initState() {
    super.initState();
    redirectToChat = widget.routePage == 'chat_page';
  }

  Future<void> signInFunction(BuildContext context, String? routePage,
      {required DateTime startDateTime,
      required DateTime endDateTime,
      required String cpsId,
      String? address,
      String? postcode,
      String? image}) async {
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    DocumentSnapshot userExist =
        await firestore.collection('users').doc(userCredential.user!.uid).get();
    DocumentSnapshot userEmailExist = await firestore
        .collection('users')
        .doc(userCredential.user!.email!)
        .get();

    if (userExist.exists || userEmailExist.exists) {
      print("User Already Exists in Database");
    } else {
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'image': userCredential.user!.photoURL,
        'uid': userCredential.user!.uid,
        'date': DateTime.now(),
      });
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatList(),
      ),
    );
  }

  Future<void> signInFunc(BuildContext context, [String? u_id]) async {
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    DocumentSnapshot userExist =
        await firestore.collection('users').doc(userCredential.user!.uid).get();
    DocumentSnapshot userEmailExist = await firestore
        .collection('users')
        .doc(userCredential.user!.email!)
        .get();

    if (userExist.exists || userEmailExist.exists) {
      print("User Already Exists in Database");
    } else {
      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'image': userCredential.user!.photoURL,
        'uid': userCredential.user!.uid,
        'date': DateTime.now(),
      });
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatList(),
      ),
    );
  }

  Future<void> _login({required String routePage}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatList(),
        ),
      );

      print('User logged in: ${userCredential.user!.email}');
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
      print('Error: $_errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);

    return Scaffold(
      appBar: CustomAppBar(title: 'Login', isLoggedInStream: isLoggedInStream),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 80),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.only(right: 15),
                    child: Text(
                      'Spare Park',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                          labelText: "Password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: _obscureText
                                  ? Colors.grey
                                  : Constants().primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          )),
                      obscureText: _obscureText,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants().primaryColor,
                    ),
                    onPressed: () {
                      if (emailController.text.length > 6 &&
                          passwordController.text.length > 6) {
                        _login(routePage: widget.routePage!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Email and password must be at least 6 characters long.",
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('Login'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(
                            startdatetime: widget.startdatetime,
                            enddatetime: widget.enddatetime,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: Constants().primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  _errorMessage.isNotEmpty
                      ? Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        )
                      : Container(),
                ],
              ),
              SizedBox(height: 50),
              Padding(
                padding: EdgeInsets.fromLTRB(15, 0, 15, 30),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.routePage == 'booking_page') {
                        await signInFunction(
                          context,
                          widget.routePage,
                          startDateTime: widget.startdatetime!,
                          endDateTime: widget.enddatetime!,
                          cpsId: widget.cpsId!,
                          address: widget.address,
                          postcode: widget.postcode,
                          image: widget.image,
                        );
                      } else {
                        if (widget.u_id != null) {
                          await signInFunc(context, widget.u_id!);
                        }
                        await signInFunc(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(350, 60),
                      textStyle: TextStyle(
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.black),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 10),
                        Text("Sign In with Google"),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
