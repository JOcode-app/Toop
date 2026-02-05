import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/order_pickup_sheet.dart';
import '../pages/order_confirmation_page.dart';

// === Services ===
import '../services/order_service.dart';
import '../services/order_service_firestore.dart'; // <-- on utilise Firestore

class EstimateCostsPage extends StatefulWidget {
  const EstimateCostsPage({super.key});

  @override
  State<EstimateCostsPage> createState() => _EstimateCostsPageState();
}

class _EstimateCostsPageState extends State<EstimateCostsPage> {
  final List<Item> _items = const [
    Item(name: 'Chemise', price: 300),
    Item(name: 'Pantalon', price: 400),
    Item(name: 'Robe', price: 500),
    Item(name: 'Costume', price: 1500),
    Item(name: 'Draps', price: 500),
    Item(name: 'Couette', price: 800),
    Item(name: 'Chaussures', price: 1500),
  ];

  final Map<String, int> _quantities = {};
  bool _express = false;
  bool _submitting = false;

  late final OrderService _orderService;

  @override
  void initState() {
    super.initState();

    /// ✅ Active l’écriture dans Firestore
    _orderService = FirestoreOrderService(FirebaseFirestore.instance);

    /// (Ne pas remettre le mock, sinon rien n’est écrit dans la base)
    /// _orderService = MockOrderService();
  }

  int get _subtotal {
    int total = 0;
    for (final it in _items) {
      final q = _quantities[it.name] ?? 0;
      total += it.price * q;
    }
    return total;
  }

  int get _feeExpress => _express ? ((_subtotal * 15) ~/ 100) : 0;
  int get _pickupDelivery => _subtotal > 0 ? 1000 : 0;
  int get _total => _subtotal + _feeExpress + _pickupDelivery;

  Future<void> _onCreateOrder() async {
    if (_subtotal == 0) return;

    final user = fa.FirebaseAuth.instance.currentUser;
    if (user == null) {
      // ⚠️ Adapte la redirection si besoin (LoginPage)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour continuer.')),
      );
      return;
    }

    final pickup = await showPickupSheet(context);
    if (pickup == null) return;

    final selected = <OrderItem>[];
    for (final it in _items) {
      final q = _quantities[it.name] ?? 0;
      if (q > 0) {
        selected.add(OrderItem(name: it.name, unitPrice: it.price, quantity: q));
      }
    }

    // --- Construction de l'ordre ---
    final order = LaundryOrder(
      id: '', // non utilisé à l’écriture (généré par Firestore)
      userId: user.uid,
      items: selected,
      express: _express,
      subtotal: _subtotal,
      expressFee: _feeExpress,
      pickupDeliveryFee: _pickupDelivery,
      total: _total,
      address: pickup.address,
      phone: pickup.phone,
      pickupAt: pickup.pickupAt,
      notes: pickup.notes,
      createdAt: DateTime.now(), // sera remplacé par serverTimestamp (voir service)
      status: 'pending',
    );

    setState(() => _submitting = true);
    try {
      // 📝 Optionnel : forcer createdAt côté serveur (voir service juste après)
      // Tu peux soit le faire ici, soit directement dans le service.
      final id = await _orderService.createOrder(order);
      debugPrint('ORDER_CREATED id=$id total=${order.total} pickupAt=${order.pickupAt}');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _subtotal > 0 && !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Estimer les coûts"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final it = _items[i];
                final q = _quantities[it.name] ?? 0;
                return Material(
                  color: Colors.white,
                  elevation: 0.5,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${it.price} FCFA / unité'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: q > 0 ? () => setState(() => _quantities[it.name] = q - 1) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$q', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        IconButton(
                          onPressed: () => setState(() => _quantities[it.name] = q + 1),
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
                _RowAmount(label: 'Sous-total', amount: _subtotal),
                _RowAmount(label: 'Express', amount: _feeExpress),
                _RowAmount(label: 'Collecte & livraison', amount: _pickupDelivery),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _RowAmount(label: 'Total estimé', amount: _total, bold: true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _onCreateOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123252),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22, width: 22,
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
      ),
    );
  }
}

class Item {
  final String name;
  final int price;
  const Item({required this.name, required this.price});
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