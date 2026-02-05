import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
// Retirer si tu n'utilises pas Google Sign-In
import 'package:google_sign_in/google_sign_in.dart' as gsi;

/// PAGE ADMIN avec 3 onglets : Commandes | Témoignages | Articles & Prix
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Espace Admin'),
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
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
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
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF123252),
            labelColor: Colors.black87,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Commandes'),
              Tab(icon: Icon(Icons.rate_review_outlined), text: 'Témoignages'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Articles & Prix'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AdminOrdersTab(),
            _AdminTestimonialsTab(),
            _AdminArticlesTab(),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// ONGLET 1 : COMMANDES (temps réel + détail + actions)
// -------------------------------------------------------
class _AdminOrdersTab extends StatelessWidget {
  const _AdminOrdersTab();

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Erreur: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

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
                    if (pickupAt != null) Text('Collecte: ${_fmtDateTime(pickupAt)}'),
                    if (address.isNotEmpty) Text('Adresse: $address'),
                    if (phone.isNotEmpty) Text('Téléphone: $phone'),
                    if (createdAt != null) Text('Créée: ${_fmtDateTime(createdAt)}'),
                  ],
                ),
                trailing: Text('$total FCFA', style: const TextStyle(fontWeight: FontWeight.w900)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _AdminOrderDetailPage(orderId: d.id, data: data),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminOrderDetailPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _AdminOrderDetailPage({required this.orderId, required this.data});

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
              const Text('Statut: ', style: TextStyle(fontWeight: FontWeight.w800)),
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
              const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w900))),
              Text('$total FCFA', style: const TextStyle(fontWeight: FontWeight.w900)),
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

  Widget _actionBtn(BuildContext context, String label, String newStatus, {bool danger = false}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? Colors.red : Colors.black87,
        side: BorderSide(color: danger ? Colors.red : Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        try {
          await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Statut mis à jour: ${_labelStatus(newStatus)}')),
          );
          Navigator.pop(context);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de mise à jour: $e')));
        }
      },
      child: Text(label),
    );
  }
}

// -------------------------------------------------------
// ONGLET 2 : TEMOIGNAGES (valider / supprimer)
// Collection: testimonials (author, content, approved, createdAt)
// -------------------------------------------------------
class _AdminTestimonialsTab extends StatelessWidget {
  const _AdminTestimonialsTab();

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('testimonials')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Erreur: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Aucun témoignage pour le moment.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = docs[i];
            final data = d.data();
            final author = (data['author'] as String?) ?? 'Anonyme';
            final content = (data['content'] as String?) ?? '';
            final approved = (data['approved'] as bool?) ?? false;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Material(
              color: Colors.white,
              elevation: 0.5,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                title: Text(author, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content),
                    if (createdAt != null)
                      Text(
                        'Ajouté le ${_fmtDateTime(createdAt)}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                  ],
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: approved ? 'Refuser' : 'Approuver',
                      icon: Icon(
                        approved ? Icons.check_circle : Icons.check_circle_outline,
                        color: approved ? Colors.green : Colors.grey,
                      ),
                      onPressed: () async => d.reference.update({'approved': !approved}),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Supprimer'),
                            content: const Text('Supprimer ce témoignage ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                            ],
                          ),
                        );
                        if (ok == true) await d.reference.delete();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------
// ONGLET 3 : ARTICLES & PRIX (CRUD)
// Collection: articles (name, price, category?, createdAt, updatedAt)
// -------------------------------------------------------
class _AdminArticlesTab extends StatelessWidget {
  const _AdminArticlesTab();

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('articles').orderBy('name');

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditArticleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un article'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Erreur: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Aucun article. Ajoute ton premier !'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data();
              final name = (data['name'] as String?)?.trim() ?? 'Article';
              final price = (data['price'] as num?)?.toInt() ?? 0;
              final category = (data['category'] as String?)?.trim() ?? '';

              return Material(
                color: Colors.white,
                elevation: 0.5,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: category.isNotEmpty ? Text('Catégorie: $category') : null,
                  trailing: Text('$price FCFA', style: const TextStyle(fontWeight: FontWeight.w900)),
                  onTap: () => _openEditArticleDialog(context, docId: d.id, initial: data),
                  onLongPress: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Supprimer l’article'),
                        content: Text('Supprimer "$name" ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
                        ],
                      ),
                    );
                    if (ok == true) await d.reference.delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditArticleDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? initial,
  }) async {
    final nameCtrl = TextEditingController(text: (initial?['name'] as String?) ?? '');
    final priceCtrl = TextEditingController(text: (initial?['price']?.toString() ?? ''));
    final categoryCtrl = TextEditingController(text: (initial?['category'] as String?) ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? 'Nouvel article' : 'Modifier l’article'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix (FCFA)', border: OutlineInputBorder()),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Prix requis';
                  final n = int.tryParse(t);
                  if (n == null || n <= 0) return 'Prix invalide';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Catégorie (optionnel)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = <String, dynamic>{
                'name': nameCtrl.text.trim(),
                'price': int.parse(priceCtrl.text.trim()),
                if (categoryCtrl.text.trim().isNotEmpty) 'category': categoryCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              try {
                if (docId == null) {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance.collection('articles').add(payload);
                } else {
                  await FirebaseFirestore.instance
                      .collection('articles')
                      .doc(docId)
                      .set(payload, SetOptions(merge: true));
                }
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: Text(docId == null ? 'Créer' : 'Enregistrer'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(docId == null ? 'Article créé' : 'Article mis à jour')),
      );
    }
  }
}

// ----------------- Helpers partagés -----------------
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

String _fmtDateTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day}/${dt.month}/${dt.year} $h:$m';
}
