import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
// Retire l'import GoogleSignIn si tu ne l'utilises pas
import 'package:google_sign_in/google_sign_in.dart' as gsi;

/// Page Admin : liste toutes les commandes en temps réel.
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
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              try {
                try {
                  await gsi.GoogleSignIn().signOut();
                } catch (_) {}
                await fa.FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur déconnexion : $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(), // <-- temps réel
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
              final data = d.data();

              final total = (data['total'] as num?)?.toInt() ?? 0;
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
                      if (pickupAt != null)
                        Text('Collecte: ${_fmtDateTime(pickupAt)}'),
                      if (address.isNotEmpty) Text('Adresse: $address'),
                      if (phone.isNotEmpty) Text('Téléphone: $phone'),
                      if (createdAt != null)
                        Text('Créée: ${_fmtDateTime(createdAt)}'),
                    ],
                  ),
                  trailing: Text(
                    '$total FCFA',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            _AdminOrderDetailPage(orderId: d.id, data: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ===================== Page Détail + Actions =====================

class _AdminOrderDetailPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _AdminOrderDetailPage({
    required this.orderId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    final status = (data['status'] as String?) ?? 'pending';
    final address = (data['address'] as String?) ?? '';
    final phone = (data['phone'] as String?) ?? '';
    final total = (data['total'] as num?)?.toInt() ?? 0;
    final userId = (data['userId'] as String?) ?? '';

    final pickupAt = (data['pickupAt'] as Timestamp?)?.toDate();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

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
          Row(
            children: [
              const Text('Statut: ',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Chip(
                label: Text(_labelStatus(status)),
                backgroundColor: _statusColor(status).withOpacity(0.12),
                labelStyle: TextStyle(color: _statusColor(status)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (pickupAt != null) Text('Collecte: ${_fmtDateTime(pickupAt)}'),
          if (createdAt != null) Text('Créée: ${_fmtDateTime(createdAt)}'),
          if (userId.isNotEmpty) Text('Client UID: $userId'),
          const SizedBox(height: 8),
          Text('Adresse: ${address.isEmpty ? "-" : address}'),
          Text('Téléphone: ${phone.isEmpty ? "-" : phone}'),

          const SizedBox(height: 12),
          const Divider(),
          const Text('Articles', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Aucun article.')
          else
            ...items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${it['name']} × ${it['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('${it['lineTotal']} FCFA'),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child:
                    Text('Total', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              Text('$total FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),

          const SizedBox(height: 20),
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _actionBtn(context, 'Confirmer', 'confirmed'),
              _actionBtn(context, 'En cours', 'in_progress'),
              _actionBtn(context, 'Terminée', 'done'),
              _actionBtn(context, 'Annuler', 'cancelled', danger: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context,
    String label,
    String newStatus, {
    bool danger = false,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? Colors.red : Colors.black87,
        side: BorderSide(color: danger ? Colors.red : Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .update({'status': newStatus});

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Statut mis à jour: ${_labelStatus(newStatus)}'),
            ),
          );
          Navigator.pop(context); // retour à la liste
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de mise à jour: $e')),
          );
        }
      },
      child: Text(label),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF8B5CF6); // violet
      case 'confirmed':
        return const Color(0xFF2563EB); // bleu
      case 'in_progress':
        return const Color(0xFFF59E0B); // orange
      case 'done':
        return const Color(0xFF16A34A); // vert
      case 'cancelled':
        return const Color(0xFFDC2626); // rouge
      default:
        return Colors.black87;
    }
  }
}

// ===================== Helpers partagés =====================

String _labelStatus(String s) {
  switch (s) {
    case 'pending':
      return 'À confirmer';
    case 'confirmed':
      return 'Confirmée';
    case 'in_progress':
      return 'En cours';
    case 'done':
      return 'Terminée';
    case 'cancelled':
      return 'Annulée';
    default:
      return s;
  }
}

String _fmtDateTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day}/${dt.month}/${dt.year} $h:$m';
}