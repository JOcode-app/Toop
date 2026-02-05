import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_service.dart';

class FirestoreOrderService implements OrderService {
  final FirebaseFirestore _db;
  FirestoreOrderService(this._db);

  @override
  Future<String> createOrder(LaundryOrder order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }
}