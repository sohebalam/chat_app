import 'package:chat_app/screens/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/chat/chat_page.dart';
import 'package:chat_app/shared/widgets/app_bar.dart';

class ChatList extends StatefulWidget {
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  User? currentUser;
  TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> searchResults = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      });
    }
    print('Current user: $currentUser');
  }

  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');

      final searchByName =
          await usersCollection.where('name', isEqualTo: query).get();

      final searchByEmail =
          await usersCollection.where('email', isEqualTo: query).get();

      setState(() {
        searchResults = searchByName.docs + searchByEmail.docs;
      });

      print("Search results: ${searchResults.length}");
    } catch (e) {
      print("Error searching users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Conversations', isLoggedInStream: Stream.value(true)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or email',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    searchUsers(searchController.text);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: searchResults.isNotEmpty
                ? ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      var user = searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user['image'] ?? ''),
                        ),
                        title: Text(user['name'] ?? ''),
                        subtitle: Text(user['email'] ?? ''),
                        onTap: () {
                          if (user.id.isNotEmpty && currentUser != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  u_id: user.id,
                                  currentUserId: currentUser!.uid,
                                ),
                              ),
                            );
                          } else {
                            print('Invalid user information');
                          }
                        },
                      );
                    },
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser!.uid)
                        .collection('messages')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No conversations found"));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var friendId = snapshot.data!.docs[index].id;
                          var lastMsg = snapshot.data!.docs[index]['last_msg'];
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(friendId)
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              var friend = snapshot.data;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(friend!['image'] ?? ''),
                                ),
                                title: Text(friend['name'] ?? ''),
                                subtitle: Text(lastMsg ?? ''),
                                onTap: () {
                                  if (friend.id.isNotEmpty &&
                                      currentUser != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          u_id: friend.id,
                                          currentUserId: currentUser!.uid,
                                        ),
                                      ),
                                    );
                                  } else {
                                    print('Invalid user information');
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
