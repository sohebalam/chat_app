import 'package:flutter/material.dart';

class SingleMessage extends StatelessWidget {
  final String friendName;
  final String datetime;
  final String message;
  final bool isMe;

  const SingleMessage({
    Key? key,
    required this.friendName,
    required this.datetime,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(friendName, style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 5),
          Material(
            color: isMe ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontSize: 15),
                  ),
                  SizedBox(height: 5),
                  Text(
                    datetime,
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
