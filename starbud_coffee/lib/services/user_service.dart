import 'package:starbud_coffe/config/supabase_config.dart';
import 'package:starbud_coffe/models/user_model.dart';

class UserService {
  final supabase = SupabaseConfig.client;

  Future<List<UserModel>> getUsers() async {
    final res = await supabase
        .from('users')
        .select()
        .order('username', ascending: true);

    return (res as List).map<UserModel>((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> addUser(
    String email,
    String username,
    String password,
    String role,
  ) async {
    final res = await supabase.auth.signUp(email: email, password: password);

    if (res.user == null) {
      throw Exception("Gagal membuat user");
    }

    final userId = res.user!.id;

    await supabase.from('users').insert({
      'id': userId,
      'username': username,
      'role': role,
      'is_active': true,
    });
  }

  Future<void> updateUser(String id, String username, String role) async {
    await supabase
        .from('users')
        .update({'username': username, 'role': role})
        .eq('id', id);
  }

  Future<void> deactivateUser(String id) async {
    await supabase.from('users').update({'is_active': false}).eq('id', id);
  }

  Future<void> activateUser(String id) async {
    await supabase.from('users').update({'is_active': true}).eq('id', id);
  }

  Future<bool> isUserUsed(String userId) async {
    final res = await supabase
        .from('orders')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return (res as List).isNotEmpty;
  }

  Future<void> deleteUser(String userId) async {
    final isUsed = await isUserUsed(userId);

    if (isUsed) {
      throw Exception("User sudah digunakan di transaksi");
    }

    await supabase.from('users').delete().eq('id', userId);
  }
}
