import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/shared/auth_service.dart';
import 'package:chat_app/shared/style/contstants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Stream<bool>? isLoggedInStream;

  CustomAppBar({
    Key? key,
    required this.title,
    this.isLoggedInStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return AppBar(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Constants().primaryColor,
      actions: [
        StreamBuilder<bool>(
          stream: isLoggedInStream ?? Stream.value(false),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!) {
              return IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await authService.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              );
            }
            return Container();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
