import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ambil data user
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }

  // Buat user baru setelah signup
  Future<void> createUser({
    required String username,
    required double latitude,
    required double longitude,
    required String address,
    String profileP = '',
    String backdropP = '',
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      final now = DateTime.now();

      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'email': user.email,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'profileP': profileP,
        'backdropP': backdropP,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  // Update sebagian data user
  Future<void> updateProfile({
    String? username,
    String? address,
    String? profileP,
    String? backdropP,
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      final data = <String, dynamic>{
        if (username != null) 'username': username,
        if (address != null) 'address': address,
        if (profileP != null) 'profileP': profileP,
        if (backdropP != null) 'backdropP': backdropP,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'updatedAt': DateTime.now(),
      };

      await _firestore.collection('users').doc(user.uid).update(data);
    }
  }
}
