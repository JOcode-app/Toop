import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Admin – Toutes les commandes'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Aucune commande pour le moment.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data()! as Map<String, dynamic>;

              final total = (data['total'] as int?) ?? 0;
              final address = (data['address'] as String?) ?? '';
              final phone = (data['phone'] as String?) ?? '';
              final status = (data['status'] as String?) ?? 'pending';
              final pickupAt = (data['pickupAt'] as Timestamp?)?.toDate();
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Material(
                color: Colors.white,
                elevation: 0.5,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  title: Text(
                    'Commande #${d.id.substring(0, 6)} • ${_labelStatus(status)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pickupAt != null) Text('Collecte: ${_fmtDateTime(pickupAt)}'),
                      Text('Adresse: $address'),
                      Text('Téléphone: $phone'),
                      if (createdAt != null) Text('Créée: ${_fmtDateTime(createdAt)}'),
                    ],
                  ),
                  trailing: Text('$total FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _AdminOrderDetailPage(orderId: d.id, data: data),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _labelStatus(String s) {
    switch (s) {
      case 'pending': return 'À confirmer';
      case 'confirmed': return 'Confirmée';
      case 'in_progress': return 'En cours';
      case 'done': return 'Terminée';
      case 'cancelled': return 'Annulée';
      default: return s;
    }
  }

  String _fmtDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m';
  }
}

class _AdminOrderDetailPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  const _AdminOrderDetailPage({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final status = (data['status'] as String?) ?? 'pending';
    final address = (data['address'] as String?) ?? '';
    final phone = (data['phone'] as String?) ?? '';
    final total = (data['total'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${orderId.substring(0, 6)}'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Statut: $status', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Adresse: $address'),
          Text('Téléphone: $phone'),
          const SizedBox(height: 12),
          const Divider(),
          const Text('Articles', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...items.map((it) => Row(
                children: [
                  Expanded(child: Text('${it['name']} × ${it['quantity']}')),
                  Text('${it['lineTotal']} FCFA'),
                ],
              )),
          const SizedBox(height: 12),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text('Total', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              Text('$total FCFA', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}