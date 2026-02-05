import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class OrderItem {
  final String name;
  final int unitPrice;
  final int quantity;

  OrderItem({
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  int get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'name': name,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'lineTotal': lineTotal,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] as String,
      unitPrice: map['unitPrice'] as int,
      quantity: map['quantity'] as int,
    );
  }
}

class LaundryOrder {
  final String id; // vide avant création
  final String userId;
  final List<OrderItem> items;
  final bool express;
  final int subtotal;
  final int expressFee;
  final int pickupDeliveryFee;
  final int total;
  final String address;
  final String phone;
  final DateTime pickupAt;
  final String? notes;
  final DateTime createdAt;
  final String status; // pending, confirmed, in_progress, done, cancelled

  LaundryOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.express,
    required this.subtotal,
    required this.expressFee,
    required this.pickupDeliveryFee,
    required this.total,
    required this.address,
    required this.phone,
    required this.pickupAt,
    required this.notes,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'express': express,
        'subtotal': subtotal,
        'expressFee': expressFee,
        'pickupDeliveryFee': pickupDeliveryFee,
        'total': total,
        'address': address,
        'phone': phone,
        'pickupAt': Timestamp.fromDate(pickupAt),
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
      };
}

abstract class OrderService {
  /// Crée une commande et retourne l'ID
  Future<String> createOrder(LaundryOrder order);
}
