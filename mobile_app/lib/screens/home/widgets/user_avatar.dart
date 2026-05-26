import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import 'package:mobile_app/theme/app_colors.dart';

/// Circular avatar for the AppBar: photo, initial letter, or fallback icon.
class HomeUserAvatar extends StatelessWidget {
  const HomeUserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const CircleAvatar(
        radius: 16,
        backgroundColor: kPrimary,
        child: Icon(Icons.person, color: Colors.white, size: 20),
      );
    }

    final photoUrl = user.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(photoUrl));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String fallbackLetter = 'U';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null &&
              data['name'] != null &&
              data['name'].toString().trim().isNotEmpty) {
            fallbackLetter = data['name']
                .toString()
                .trim()
                .substring(0, 1)
                .toUpperCase();
          } else if (user.displayName != null &&
              user.displayName!.trim().isNotEmpty) {
            fallbackLetter = user.displayName!
                .trim()
                .substring(0, 1)
                .toUpperCase();
          } else if (user.email != null && user.email!.trim().isNotEmpty) {
            fallbackLetter = user.email!.trim().substring(0, 1).toUpperCase();
          }
        } else if (user.displayName != null &&
            user.displayName!.trim().isNotEmpty) {
          fallbackLetter = user.displayName!
              .trim()
              .substring(0, 1)
              .toUpperCase();
        } else if (user.email != null && user.email!.trim().isNotEmpty) {
          fallbackLetter = user.email!.trim().substring(0, 1).toUpperCase();
        }

        return CircleAvatar(
          radius: 16,
          backgroundColor: kPrimary,
          child: Text(
            fallbackLetter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
