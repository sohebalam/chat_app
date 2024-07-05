import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/screens/chat/chat_page.dart';
import 'package:chat_app/shared/auth_service.dart';
import 'package:chat_app/shared/widgets/app_bar.dart';

class ChatList extends StatefulWidget {
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  late User? currentUser;
  bool isLoading = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    print("Current User: ${currentUser?.uid}");
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Conversations',
        isLoggedInStream: isLoggedInStream,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by email or name",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .collection('messages')
                  .snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data.docs.length == 0) {
                  return Center(
                    child: Text("No Chats Available!"),
                  );
                }
                print("Chats Found: ${snapshot.data.docs.length}");
                return ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    var friendId = snapshot.data.docs[index].id;
                    var lastMsg = snapshot.data.docs[index]['last_msg'];
                    print("Friend ID: $friendId, Last Message: $lastMsg");
                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(friendId)
                          .get(),
                      builder: (context, AsyncSnapshot asyncSnapshot) {
                        if (asyncSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container();
                        }
                        if (!asyncSnapshot.hasData ||
                            !asyncSnapshot.data.exists) {
                          return Container();
                        }
                        var friend = asyncSnapshot.data;
                        if (searchQuery.isEmpty ||
                            friend['email']
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase()) ||
                            friend['name']
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase())) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  friend['image'] ?? ''),
                            ),
                            title: Text(friend['name'] ?? 'Unknown User'),
                            subtitle: Text(
                              "$lastMsg",
                              style: TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    u_id: friend.id,
                                    currentUserId: currentUser!.uid,
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          return Container();
                        }
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
