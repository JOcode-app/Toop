import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Brancher à Firebase/Backend plus tard pour lister les vraies commandes
    final orders = <OrderItem>[]; // vide = état initial

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes commandes"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: orders.isEmpty
          ? const _EmptyOrders()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) => _OrderTile(item: orders[i]),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: orders.length,
            ),
    );
  }
}

class OrderItem {
  final String id;
  final String title;   // ex: "Pressing costume"
  final String status;  // ex: "En cours", "Livré", "En attente"
  final String eta;     // ex: "Demain 18h"
  final int amount;     // total FCFA

  OrderItem({
    required this.id,
    required this.title,
    required this.status,
    required this.eta,
    required this.amount,
  });
}

class _OrderTile extends StatelessWidget {
  final OrderItem item;
  const _OrderTile({required this.item});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'livré':
        return const Color(0xFF34A853);
      case 'en cours':
        return const Color(0xFF2E5BFF);
      default:
        return const Color(0xFF9AA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: ListTile(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('ETA: ${item.eta}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${item.amount} FCFA', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(item.status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(item.status, style: TextStyle(color: _statusColor(item.status), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        onTap: () {
          // TODO: Détail de commande
        },
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFF9AA3AF)),
            SizedBox(height: 10),
            Text(
              "Vous n’avez pas encore de commande.\nPassez votre première commande pour la retrouver ici.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}