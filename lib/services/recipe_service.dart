import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRecipesByMenu(String menuId) async {
    final res = await supabase
        .from('recipes')
        .select('*, stocks(id, name, unit)')
        .eq('menu_id', menuId);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> addRecipe(
    String menuId,
    String stockId,
    int qty,
    bool isOptional,
  ) async {
    await supabase.from('recipes').insert({
      'menu_id': menuId,
      'stock_id': stockId,
      'quantity': qty,
      'is_optional': isOptional,
    });
  }

  Future<void> deleteRecipe(String recipeId, String menuId) async {
    await supabase.from('recipes').delete().eq('id', recipeId);
  }

  Future<void> updateMenuStatusBasedOnRecipe(String menuId) async {
    final recipes = await supabase
        .from('recipes')
        .select('id')
        .eq('menu_id', menuId);

    final hasRecipe = (recipes as List).isNotEmpty;

    await supabase.from('menu').update({'status': hasRecipe}).eq('id', menuId);
  }

  Future<List<String>> getMenuIdsWithRecipe() async {
    final res = await supabase.from('recipes').select('menu_id').limit(200);

    final list = List<Map<String, dynamic>>.from(res);

    return list.map((e) => e['menu_id'] as String).toSet().toList();
  }
}
