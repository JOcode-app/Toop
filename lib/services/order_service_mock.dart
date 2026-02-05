import 'dart:math';
import 'order_service.dart';

class MockOrderService implements OrderService {
  @override
  Future<String> createOrder(LaundryOrder order) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return 'local_${Random().nextInt(999999)}';
  }
}
