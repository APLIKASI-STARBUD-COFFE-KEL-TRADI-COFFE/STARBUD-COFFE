import 'package:starbud_coffe/config/supabase_config.dart';
import 'package:starbud_coffe/models/menu_model.dart';

class MenuService {
  final supabase = SupabaseConfig.client;

  Future<List<MenuModel>> getMenus() async {
    final res = await supabase
        .from('menu')
        .select('''
        *,
        categories(name),
        recipes!left(id)
      ''')
        .order('name', ascending: true);

    return (res as List).map<MenuModel>((e) {
      final hasRecipe = (e['recipes'] as List).isNotEmpty;

      return MenuModel.fromJson({...e, 'has_recipe': hasRecipe});
    }).toList();
  }


  Future<List<Map<String, dynamic>>> getRecipeForMenu(String menuId) async {
    try {
      final response = await supabase
          .from('recipes')
          .select('''
            quantity,
            is_optional,
            stocks (
              id,
              name,
              quantity,
              unit
            )
          ''')
          .eq('menu_id', menuId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching recipe: $e");
      return [];
    }
  }


  Future<void> addMenu(
    String name,
    int price,
    int stock,
    String categoryId,
    String? imageUrl,
  ) async {
    await supabase.from('menu').insert({
      'name': name,
      'price': price,
      'stock': stock,
      'category_id': categoryId,
      'status': false,
      'image_url': imageUrl,
    });
  }


  Future<void> updateMenu(
    String id,
    String name,
    int price,
    int stock,
    String categoryId,
    String? imageUrl,
  ) async {
    await supabase
        .from('menu')
        .update({
          'name': name,
          'price': price,
          'stock': stock,
          'category_id': categoryId,
          'image_url': imageUrl,
        })
        .eq('id', id);
  }

  Future<void> updateStatus(String id, bool status) async {
    await supabase.from('menu').update({'status': status}).eq('id', id);
  }

  Future<void> deleteMenu(String id) async {
    await supabase.from('menu').delete().eq('id', id);
  }

  Stream<List<MenuModel>> streamMenus() {
    return supabase
        .from('menu')
        .stream(primaryKey: ['id'])
        .map((data) async {
          final result = await supabase
              .from('menu')
              .select('*, categories(name)')
              .order('name', ascending: true);

          return (result as List)
              .map<MenuModel>((e) => MenuModel.fromJson(e))
              .toList();
        })
        .asyncMap((event) async => await event);
  }
}
