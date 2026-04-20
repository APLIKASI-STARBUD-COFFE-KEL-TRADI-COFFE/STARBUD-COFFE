import 'package:starbud_coffe/config/supabase_config.dart';

class OrderService {
  final supabase = SupabaseConfig.client;

  Future<void> createOrder(String userId, int total, List<dynamic> cart) async {
    try {
      for (var item in cart) {
        final selectedRecipe = (item['selected_recipe'] as List)
            .where((r) => r['is_selected'] == true)
            .toList();

        for (var r in selectedRecipe) {
          final stock = r['stocks'];

          double currentStock =
              double.tryParse(stock['quantity'].toString()) ?? 0;

          double needed =
              (double.tryParse(r['quantity'].toString()) ?? 0) * item['qty'];

          if (currentStock < needed) {
            throw Exception(
              'Stok ${stock['name']} tidak mencukupi untuk ${item['name']}',
            );
          }
        }
      }

      final order = await supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'total': total,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final orderId = order['id'];

      for (var item in cart) {
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'menu_id': item['id'],
          'qty': item['qty'],
          'price': item['price'],
        });

        final selectedRecipe = (item['selected_recipe'] as List)
            .where((r) => r['is_selected'] == true)
            .toList();

        final formattedRecipe = selectedRecipe
            .map((r) {
              final stockId = r['stocks']?['id'];

              if (stockId == null) return null; 

              return {'stock_id': stockId, 'quantity': r['quantity']};
            })
            .where((e) => e != null)
            .toList();

        await supabase.rpc(
          'reduce_stock_by_menu',
          params: {
            'selected_recipe': formattedRecipe,
            'order_qty': item['qty'],
          },
        );
      }
    } catch (e) {
      print("Error createOrder: $e");
      rethrow;
    }
  }
}
