import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbud_coffe/models/user_model.dart';
import 'package:starbud_coffe/services/auth_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isPasswordHidden = true;
  bool rememberMe = false;

  int failedAttempts = 0;
  DateTime? lockUntil;

  int remainingSeconds = 0;
  Timer? lockTimer;

  static const Color ivoryColor = Color(0xFFFFF8E1);
  static const Color darkCoffee = Color(0xFF3E2723);
  static const Color gold1 = Color(0xFFB76212);
  static const Color gold2 = Color(0xFFC88C0C);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    lockTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();

    final isRemember = prefs.getBool('rememberMe') ?? false;
    final savedEmail = prefs.getString('email') ?? '';

    if (isRemember) {
      setState(() {
        rememberMe = true;
        email.text = savedEmail;
      });
    }
  }

  void _handleLoginError(String message, {bool isLockMessage = false}) {
    failedAttempts++;

    if (failedAttempts >= 3) {
      lockUntil = DateTime.now().add(const Duration(seconds: 30));
      _startLockCountdown();

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terlalu banyak percobaan. Login dikunci 30 detik"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isLockMessage ? Colors.red : Colors.redAccent,
      ),
    );
  }

  Future<void> login() async {
    if (lockUntil != null && DateTime.now().isBefore(lockUntil!)) {
      final seconds = lockUntil!.difference(DateTime.now()).inSeconds;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Terlalu banyak percobaan. Coba lagi dalam $seconds detik",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final authUser = await auth.login(
        email.text.trim(),
        password.text.trim(),
      );

      if (authUser == null) throw "Login gagal. Periksa email dan password.";

      final res = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (res == null) throw "Data profil tidak ditemukan";

      final user = UserModel.fromJson(res);

      if (!user.isActive) {
        throw "Akun tidak aktif. Hubungi admin.";
      }

      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', true);
        await prefs.setString('email', email.text.trim());
      }

      if (!mounted) return;

      failedAttempts = 0;
      lockUntil = null;
      lockTimer?.cancel();
      remainingSeconds = 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Selamat datang kembali, ${user.username}!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
      );
    } on AuthException catch (e) {
      _handleLoginError(e.message);
    } on PostgrestException catch (e) {
      _handleLoginError("Error database: ${e.message}");
    } on SocketException {
      _handleLoginError("Tidak ada koneksi internet");
    } catch (e) {
      _handleLoginError("Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startLockCountdown() {
    remainingSeconds = 30;

    lockTimer?.cancel();

    lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        timer.cancel();
        lockUntil = null;

        setState(() {});
      } else {
        remainingSeconds--;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ivoryColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: CurveClipper(),
              child: Container(
                height: screenHeight * 0.35,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/login.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [gold1, gold2],
                      ).createShader(bounds),
                      child: Text(
                        "StarBud Coffee",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      "SISTEM OPERASIONAL & STOK",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 70),
                    _buildTextField(
                      controller: email,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email wajib diisi";
                        }

                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

                        if (!emailRegex.hasMatch(value.trim())) {
                          return "Format email tidak valid";
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: password,
                      label: "Password",
                      icon: Icons.lock_outline,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Password wajib diisi";
                        }

                        if (value.trim().length < 6) {
                          return "Minimal 6 karakter";
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const SizedBox(width: 3),
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: rememberMe,
                            activeColor: gold1,
                            onChanged: (v) async {
                              if (v == null) return;
                              setState(() => rememberMe = v);

                              final prefs =
                                  await SharedPreferences.getInstance();

                              if (!v) {
                                await prefs.remove('rememberMe');
                                await prefs.remove('email');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Remember Me",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: darkCoffee,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            isLoading ||
                                (lockUntil != null &&
                                    DateTime.now().isBefore(lockUntil!))
                            ? null
                            : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkCoffee,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: ivoryColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : (lockUntil != null &&
                                  DateTime.now().isBefore(lockUntil!))
                            ? Text(
                                "Tunggu ${remainingSeconds}s",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "LOGIN",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isPasswordHidden : false,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(color: darkCoffee),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: gold1),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => isPasswordHidden = !isPasswordHidden),
              )
            : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: gold1, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
