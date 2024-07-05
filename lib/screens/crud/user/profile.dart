import 'package:chat_app/screens/auth/auth_screen.dart';
import 'package:chat_app/shared/style/contstants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/shared/auth_service.dart';
import 'package:chat_app/shared/widgets/app_bar.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? currentUser;
  bool isLoading = true;
  bool canDelete = true;
  String userName = '';
  String userPhoto = '';

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      checkBookedParkingSpaces();
      retrieveUserData();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
  }

  Future<void> retrieveUserData() async {
    if (currentUser!.providerData[0].providerId == 'password') {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;
      setState(() {
        userName = userData?['name'] ?? '';
        userPhoto = userData?['image'] ?? '';
      });
    } else {
      setState(() {
        userName = currentUser!.displayName ?? '';
        userPhoto = currentUser!.photoURL ?? '';
      });
    }
  }

  Future<void> checkBookedParkingSpaces() async {
    setState(() {
      isLoading = true;
    });

    final QuerySnapshot parkingSpacesSnapshot = await FirebaseFirestore.instance
        .collection('parking_spaces')
        .where('u_id', isEqualTo: currentUser!.uid)
        .get();

    for (final DocumentSnapshot parkingSpaceDoc in parkingSpacesSnapshot.docs) {
      final String parkingSpaceId = parkingSpaceDoc.id;
      final QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('p_id', isEqualTo: parkingSpaceId)
          .limit(1)
          .get();

      if (bookingsSnapshot.docs.isNotEmpty) {
        setState(() {
          canDelete = false;
          isLoading = false;
        });
        return;
      }
    }

    setState(() {
      canDelete = true;
      isLoading = false;
    });
  }

  Future<void> deleteUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .delete();
    await currentUser!.delete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Profile'),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Transform.translate(
                offset: Offset(0, -60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 16),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(userPhoto ?? ''),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Name: $userName',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Email: ${currentUser!.email}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: canDelete ? deleteUser : null,
                      child: Text('Delete Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
                    if (canDelete == false)
                      Padding(
                        padding: EdgeInsets.fromLTRB(30, 20, 20, 0),
                        child: const Text(
                          'You have a booked parking space, please cancel the booking or contact admin to delete your account',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                  ],
                ),
              ),
            ),
    );
  }
}
