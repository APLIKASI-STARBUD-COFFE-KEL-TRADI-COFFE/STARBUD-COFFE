import 'package:starbud_coffe/config/supabase_config.dart';
import 'package:starbud_coffe/models/category_model.dart';

class CategoryService {
  final supabase = SupabaseConfig.client;

  Future<List<CategoryModel>> getCategories() async {
    final res = await supabase
        .from('categories')
        .select()
        .order('name', ascending: true);

    return res.map<CategoryModel>((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> getActiveCategories() async {
    final res = await supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return res.map<CategoryModel>((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> addCategory(String name) async {
    await supabase.from('categories').insert({'name': name, 'is_active': true});
  }

  Future<void> updateCategory(String id, String newName) async {
    await supabase.from('categories').update({'name': newName}).eq('id', id);
  }

  Future<void> deactivateCategory(String id) async {
    await supabase.from('categories').update({'is_active': false}).eq('id', id);
  }

  Future<void> updateStatus(String id, bool status) async {
    await supabase
        .from('categories')
        .update({'is_active': status})
        .eq('id', id);
  }

  Future<bool> isCategoryUsed(String categoryId) async {
    final res = await supabase
        .from('menu')
        .select('id')
        .eq('category_id', categoryId)
        .limit(1);

    return res.isNotEmpty;
  }

  Stream<List<CategoryModel>> streamCategories() {
    return supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((data) => data.map((e) => CategoryModel.fromJson(e)).toList());
  }

  Future<void> deleteCategory(String id) async {
    await supabase.from('categories').delete().eq('id', id);
  }

  Future<bool> isCategoryNameExist(String name) async {
    final res = await supabase
        .from('categories')
        .select('id')
        .ilike('name', name)
        .limit(1);

    return res.isNotEmpty;
  }
}
