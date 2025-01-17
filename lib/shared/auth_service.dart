import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/shared/functions.dart';

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final StreamController<UserModel?> _userController =
      StreamController<UserModel?>();

  UserModel? _userFromFirebase(auth.User? user) {
    if (user == null) {
      return null;
    }
    return UserModel(uid: user.uid, email: user.email ?? "");
  }

  Stream<UserModel?>? get user {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
  }

  Future<UserModel?> signInWithEmailAndPassword(
      BuildContext context, String email, String password,
      {String? prior_page,
      LatLng? location,
      List<List<dynamic>>? results,
      DateTime? startdatetime,
      DateTime? enddatetime}) async {
    if (isEmailValid(email) && password.length > 6) {
      try {
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        return _userFromFirebase(credential.user);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid email or password."),
          ),
        );
        return null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Email must be valid and password must be at least 6 characters long.",
          ),
        ),
      );
      return null;
    }
  }

  Future<UserModel?> createUserWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
    File image,
    String name, {
    String? prior_page,
    LatLng? location,
    List<List<dynamic>>? results,
    DateTime? startdatetime,
    DateTime? enddatetime,
  }
      // String? uid
      ) async {
    if (isEmailValid(email) && password.length > 6) {
      try {
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final ref = FirebaseStorage.instance
            .ref()
            .child('users/${credential.user!.uid}/image.jpg');
        final uploadTask = ref.putFile(image);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid);
        await userDoc.set({
          'name': name,
          'email': email,
          'image': downloadUrl,
          'uid': userDoc.id
        });

        return _userFromFirebase(credential.user);
      } catch (e) {
        print(e.toString());
        return null;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Email must be valid and password must be at least 6 characters long.",
          ),
        ),
      );
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  logout() {}

  isExistingUser(String email) {}
}
