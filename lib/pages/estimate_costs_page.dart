import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/order_pickup_sheet.dart';
import '../pages/order_confirmation_page.dart';

// Services
import '../services/order_service.dart';
import '../services/order_service_firestore.dart';

class EstimateCostsPage extends StatefulWidget {
  const EstimateCostsPage({super.key});

  @override
  State<EstimateCostsPage> createState() => _EstimateCostsPageState();
}

class _EstimateCostsPageState extends State<EstimateCostsPage> {
  /// Quantités choisies par article (clé = doc.id)
  final Map<String, int> _quantities = {};
  bool _express = false;
  bool _submitting = false;

  late final OrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = FirestoreOrderService(FirebaseFirestore.instance);
  }

  // ---- Calculs dynamiques ----
  int _subtotalFrom(List<_Article> arts) {
    int total = 0;
    for (final a in arts) {
      final q = _quantities[a.id] ?? 0;
      total += a.price * q;
    }
    return total;
  }

  int _feeExpressFrom(int subtotal) => _express ? ((subtotal * 15) ~/ 100) : 0;
  int _pickupDeliveryFrom(int subtotal) => subtotal > 0 ? 1000 : 0;
  int _totalFrom(int subtotal) => subtotal + _feeExpressFrom(subtotal) + _pickupDeliveryFrom(subtotal);

  // ---- Création de commande ----
  Future<void> _onCreateOrder(List<_Article> arts) async {
    final subtotal = _subtotalFrom(arts);
    if (subtotal == 0) return;

    final user = fa.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour continuer.')),
      );
      return;
    }

    final pickup = await showPickupSheet(context);
    if (pickup == null) return;

    final selected = <OrderItem>[];
    for (final a in arts) {
      final q = _quantities[a.id] ?? 0;
      if (q > 0) {
        selected.add(OrderItem(name: a.name, unitPrice: a.price, quantity: q));
      }
    }

    final subtotal2 = _subtotalFrom(arts);
    final feeExpress = _feeExpressFrom(subtotal2);
    final pickupFee = _pickupDeliveryFrom(subtotal2);
    final total = _totalFrom(subtotal2);

    final order = LaundryOrder(
      id: '',
      userId: user.uid,
      items: selected,
      express: _express,
      subtotal: subtotal2,
      expressFee: feeExpress,
      pickupDeliveryFee: pickupFee,
      total: total,
      address: pickup.address,
      phone: pickup.phone,
      pickupAt: pickup.pickupAt,
      notes: pickup.notes,
      createdAt: DateTime.now(), // sera remplacé côté service par serverTimestamp
      status: 'pending',
    );

    setState(() => _submitting = true);
    try {
      final id = await _orderService.createOrder(order);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commande enregistrée: $id')),
      );

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderConfirmationPage(orderId: id)),
      );

      setState(() {
        _quantities.clear();
        _express = false;
      });
    } catch (e, st) {
      debugPrint('ORDER_CREATE_ERROR: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estimer les coûts"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('articles')
            .orderBy('name')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Erreur: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          final articles = docs.map((d) => _Article.fromDoc(d)).where((a) => a.price > 0 && a.name.isNotEmpty).toList();

          if (articles.isEmpty) {
            return const _EmptyArticlesNotice();
          }

          final subtotal = _subtotalFrom(articles);
          final feeExpress = _feeExpressFrom(subtotal);
          final pickupFee = _pickupDeliveryFrom(subtotal);
          final total = _totalFrom(subtotal);
          final canSubmit = subtotal > 0 && !_submitting;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final it = articles[i];
                    final q = _quantities[it.id] ?? 0;
                    return Material(
                      color: Colors.white,
                      elevation: 0.5,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${it.price} FCFA / unité'
                            '${it.category.isNotEmpty ? '  •  ${it.category}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: q > 0 ? () => setState(() => _quantities[it.id] = q - 1) : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$q', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            IconButton(
                              onPressed: () => setState(() => _quantities[it.id] = q + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Option express (+15%)'),
                      value: _express,
                      onChanged: (v) => setState(() => _express = v),
                    ),
                    const SizedBox(height: 6),
                    _RowAmount(label: 'Sous-total', amount: subtotal),
                    _RowAmount(label: 'Express', amount: feeExpress),
                    _RowAmount(label: 'Collecte & livraison', amount: pickupFee),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _RowAmount(label: 'Total estimé', amount: total, bold: true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canSubmit ? () => _onCreateOrder(articles) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF123252),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Planifier une collecte'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

// ---- Modèle local pour un article Firestore ----
class _Article {
  final String id;
  final String name;
  final int price;
  final String category;

  _Article({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  factory _Article.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return _Article(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      price: (d['price'] as num?)?.toInt() ?? 0,
      category: (d['category'] as String?)?.trim() ?? '',
    );
  }
}

class _RowAmount extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;
  const _RowAmount({required this.label, required this.amount, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text('$amount FCFA', style: style),
      ],
    );
  }
}

class _EmptyArticlesNotice extends StatelessWidget {
  const _EmptyArticlesNotice();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF9AA3AF)),
            SizedBox(height: 10),
            Text(
              "Aucun article disponible.\nAjoute des articles dans l’espace Admin > Articles & Prix.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}