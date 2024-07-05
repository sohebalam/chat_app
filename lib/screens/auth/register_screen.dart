import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/shared/auth_service.dart';
import 'package:chat_app/shared/functions.dart';
import 'package:chat_app/shared/style/contstants.dart';
import 'package:chat_app/shared/widgets/textField.dart';
import 'package:chat_app/shared/widgets/app_bar.dart';
import 'package:chat_app/shared/widgets/errorMessage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final DateTime? startdatetime;
  final DateTime? enddatetime;

  const RegisterScreen({
    Key? key,
    this.startdatetime,
    this.enddatetime,
  }) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  final picker = ImagePicker();
  File? _image;
  String? _errorMessage;
  bool submitted = false;
  bool _obscureText = true;

  _registerUser() async {
    setState(() {
      submitted = true;
    });

    if (_image == null) {
      setState(() {
        _errorMessage = 'Please select an image.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Upload the user's image to Firebase Storage and get the download URL
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${credential.user!.uid}/image.jpg');
      final uploadTask = ref.putFile(_image!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Create a new document for the user in Firestore
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid);
      await userDoc.set({
        'name': nameController.text,
        'email': emailController.text,
        'image': downloadUrl,
        'uid': userDoc.id,
        'date': DateTime.now(),
      });

      // Show success message and navigate to chat list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New user registered successfully!'),
        ),
      );
      Navigator.pushReplacementNamed(context, '/chat_list');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _getImage() async {
    final action = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.camera);
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;

    final pickedFile = await picker.pickImage(source: action);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _errorMessage = null;
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      appBar:
          CustomAppBar(title: 'Register', isLoggedInStream: isLoggedInStream),
      body: Container(
        margin: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: !submitted || nameController.text.isNotEmpty
                        ? null
                        : 'Please enter your name.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: !submitted ||
                            emailController.text.isEmpty ||
                            isEmailValid(emailController.text)
                        ? null
                        : 'Please enter a valid email address.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  obscureText: _obscureText,
                  controller: passwordController,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      errorText:
                          !submitted || passwordController.text.isNotEmpty
                              ? null
                              : 'Please enter your password.',
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
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              GestureDetector(
                onTap: _getImage,
                child: Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Constants().tertiaryColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Select Image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              if (_image != null)
                Container(
                  height: 200.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(
                height: 16.0,
              ),
              if (_isLoading) Center(child: CircularProgressIndicator()),
              buildErrorMessage(context, _errorMessage),
              Container(
                height: 40.0,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants().primaryColor,
                  ),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
