import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<User?> login(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = res.user;

    if (user == null) return null;

    final userData = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    if (userData['is_active'] == false) {
      throw Exception("Akun Anda telah dinonaktifkan. Silakan hubungi admin.");
    }

    return user;
  }
}
