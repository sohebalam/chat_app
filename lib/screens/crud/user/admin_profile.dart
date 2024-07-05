import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/shared/auth_service.dart';
import 'package:chat_app/shared/widgets/app_bar.dart';

class AdminUserProfilePage extends StatefulWidget {
  final String userId;

  AdminUserProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _AdminUserProfilePageState createState() => _AdminUserProfilePageState();
}

class _AdminUserProfilePageState extends State<AdminUserProfilePage> {
  User? currentUser;
  bool isLoading = true;
  bool canDelete = true;
  String userName = '';
  String userPhoto = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    checkBookedParkingSpaces();
    retrieveUserData();
  }

  Future<void> retrieveUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;
      setState(() {
        userName = userData?['name'] ?? '';
        userPhoto = userData?['image'] ?? '';
        userEmail = userData?['email'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<void> checkBookedParkingSpaces() async {
    setState(() {
      isLoading = true;
    });

    try {
      final QuerySnapshot parkingSpacesSnapshot = await FirebaseFirestore
          .instance
          .collection('parking_spaces')
          .where('u_id', isEqualTo: widget.userId)
          .get();

      for (final DocumentSnapshot parkingSpaceDoc
          in parkingSpacesSnapshot.docs) {
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
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check booked parking spaces: $e')),
      );
    }
  }

  Future<void> deleteUser() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();

      await FirebaseAuth.instance.currentUser!.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted successfully'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);

    return Scaffold(
      appBar:
          CustomAppBar(title: 'Profile', isLoggedInStream: isLoggedInStream),
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
                      backgroundImage: userPhoto.isNotEmpty
                          ? NetworkImage(userPhoto)
                          : AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Name: $userName',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Email: $userEmail',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: canDelete ? deleteUser : null,
                      child: Text('Delete Account'),
                    ),
                    if (!canDelete)
                      Padding(
                        padding: EdgeInsets.fromLTRB(30, 20, 20, 0),
                        child: Text(
                          'You have a booked parking space, please cancel the booking or contact admin to delete your account',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
