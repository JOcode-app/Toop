import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // Mémorise le dernier statut connu par commande pour détecter les changements
  final Map<String, String> _lastStatuses = {};
  // Évite de montrer plusieurs fois le même SnackBar pour la même commande
  final Set<String> _alreadyNotified = {};

  @override
  Widget build(BuildContext context) {
    final user = fa.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Mes commandes"),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: Colors.black87,
        ),
        body: const _EmptyOrders(
          customMessage:
              "Vous devez être connecté(e) pour voir vos commandes.",
        ),
      );
    }

    final uid = user.uid;

    // On écoute uniquement les commandes de l'utilisateur (tri par date de création)
    final query = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes commandes"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            // Message plus propre si l’index n’est pas encore prêt
            final msg = snap.error.toString();
            final isIndexError =
                msg.contains('failed-precondition') && msg.contains('index');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isIndexError
                      ? "L'index Firestore requis est en cours de création.\nRéessaie dans 1 à 2 minutes."
                      : 'Erreur: $msg',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          // Détection des changements de statut -> SnackBar "acceptée"
          _handleStatusChanges(context, docs);

          if (docs.isEmpty) {
            return const _EmptyOrders();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data();

              final id = d.id;
              final title = _titleFromItems(data['items']);
              final rawStatus = (data['status'] as String?) ?? 'pending';
              final total = (data['total'] as num?)?.toInt() ?? 0;

              final pickupAt = (data['pickupAt'] as Timestamp?)?.toDate();
              final eta = pickupAt != null ? _fmtDateTime(pickupAt) : '—';

              return _OrderTile(
                item: OrderItem(
                  id: id,
                  title: title,
                  status: _labelStatus(rawStatus),
                  eta: eta,
                  amount: total,
                ),
                // Affiche un petit badge "Nouveau" si le statut vient d’être confirmé
                justConfirmed: _justConfirmed(id, rawStatus),
              );
            },
          );
        },
      ),
    );
  }

  /// Compare les statuts actuels aux précédents et affiche une alerte
  /// si une commande passe à "confirmed".
  void _handleStatusChanges(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    for (final d in docs) {
      final current = (d.data()['status'] as String?) ?? 'pending';
      final previous = _lastStatuses[d.id];

      // Met à jour la mémoire
      _lastStatuses[d.id] = current;

      // Si le statut vient de passer à "confirmed", notifie (une seule fois)
      if (previous != null &&
          previous != current &&
          current == 'confirmed' &&
          !_alreadyNotified.contains(d.id)) {
        _alreadyNotified.add(d.id);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final shortId = d.id.substring(0, 6);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Votre commande #$shortId a été acceptée ✅'),
            ),
          );
        });
      }
    }
  }

  /// Indique si on doit afficher un petit badge "Nouveau" sur la tuile
  bool _justConfirmed(String id, String rawStatus) {
    final label = rawStatus.toLowerCase();
    final last = _lastStatuses[id];
    return last != null && last != label && label == 'confirmed';
  }

  /// Construit un titre sympa à partir des items (ex: "Chemise ×2, Pantalon ×1")
  String _titleFromItems(dynamic itemsField) {
    final items = (itemsField as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    if (items.isEmpty) return 'Commande';

    final parts = <String>[];
    for (final it in items.take(3)) {
      final name = (it['name'] as String?) ?? 'Article';
      final qty = (it['quantity'] as num?)?.toInt() ?? 1;
      parts.add('$name ×$qty');
    }
    final label = parts.join(', ');
    // Ajoute "…" s’il y a plus d’items
    return items.length > 3 ? '$label…' : label;
  }

  String _labelStatus(String s) {
    switch (s) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Acceptée';
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
}

// ======= Modèle simple pour l'affichage =======

class OrderItem {
  final String id;
  final String title;   // ex: "Chemise ×2, Pantalon ×1"
  final String status;  // "En attente", "Acceptée", ...
  final String eta;     // ex: "05/02/2026 18:00"
  final int amount;     // total FCFA

  OrderItem({
    required this.id,
    required this.title,
    required this.status,
    required this.eta,
    required this.amount,
  });
}

// ======= Tuile d'une commande =======

class _OrderTile extends StatelessWidget {
  final OrderItem item;
  final bool justConfirmed;

  const _OrderTile({required this.item, this.justConfirmed = false});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'terminée':
        return const Color(0xFF34A853);
      case 'en cours':
        return const Color(0xFF2E5BFF);
      case 'acceptée':
        return const Color(0xFF10B981);
      case 'annulée':
        return const Color(0xFFDC2626);
      case 'en attente':
      default:
        return const Color(0xFF9AA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (justConfirmed)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Nouveau',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('Collecte: ${item.eta}'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${item.amount} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.status,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Page détail client si besoin
        },
      ),
    );
  }
}

// ======= Écran vide =======

class _EmptyOrders extends StatelessWidget {
  final String? customMessage;
  const _EmptyOrders({this.customMessage});

  @override
  Widget build(BuildContext context) {
    final txt = customMessage ??
        "Vous n’avez pas encore de commande.\nPassez votre première commande pour la retrouver ici.";
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 42, color: Color(0xFF9AA3AF)),
            const SizedBox(height: 10),
            Text(
              txt,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}