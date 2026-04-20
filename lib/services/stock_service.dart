import 'package:starbud_coffe/config/supabase_config.dart';
import 'package:starbud_coffe/models/stock_model.dart';

class StockService {
  final supabase = SupabaseConfig.client;

  Future<List<StockModel>> getStocks() async {
    final res = await supabase
        .from('stocks')
        .select()
        .order('name', ascending: true);

    return (res as List).map((e) => StockModel.fromJson(e)).toList();
  }

  Future<List<StockModel>> getLowStockItems() async {
    final res = await supabase.from('stocks').select();

    final allStocks = (res as List).map((e) => StockModel.fromJson(e)).toList();

    return allStocks.where((s) => s.quantity <= s.minStock).toList();
  }

  Future<void> addStock(StockModel stock) async {
    await supabase.from('stocks').insert({
      'name': stock.name,
      'quantity': stock.quantity,
      'min_stock': stock.minStock,
      'unit': stock.unit,
    });
  }

  Future<void> updateStock(StockModel updatedStock) async {
    await supabase
        .from('stocks')
        .update(updatedStock.toJson())
        .eq('id', updatedStock.id);
  }

  Future<void> deleteStock(String id) async {
    await supabase.from('stocks').delete().eq('id', id);
  }
}
