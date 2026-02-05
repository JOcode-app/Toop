import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Récupère phone et address depuis `users/{uid}` (sinon valeurs vides)
  Future<Map<String, String>> fetchProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data() ?? {};
    return {
      'phone': (data['phone'] as String?) ?? '',
      'address': (data['address'] as String?) ?? '',
    };
  }

  /// Met à jour/ajoute les champs (merge)
  Future<void> upsertProfile(
    String uid, {
    String? phone,
    String? address,
  }) async {
    final payload = <String, dynamic>{};
    if (phone != null) payload['phone'] = phone;
    if (address != null) payload['address'] = address;
    if (payload.isEmpty) return;
    await _db.collection('users').doc(uid).set(payload, SetOptions(merge: true));
  }
}