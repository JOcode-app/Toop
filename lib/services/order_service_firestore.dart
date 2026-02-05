// lib/services/order_service_firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_service.dart';

/// Service d'écriture des commandes dans Firestore.
class FirestoreOrderService implements OrderService {
  final FirebaseFirestore _db;
  FirestoreOrderService(this._db);

  /// Crée un document dans 'orders' et retourne l'ID généré par Firestore.
  /// - Définit createdAt côté serveur pour un tri cohérent.
  @override
  Future<String> createOrder(LaundryOrder order) async {
    try {
      final data = order.toMap();

      // ✅ createdAt côté serveur (plus fiable qu'un DateTime local)
      data['createdAt'] = FieldValue.serverTimestamp();

      final ref = await _db.collection('orders').add(data);
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception('Firestore error [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while creating order: $e');
    }
  }
}