import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:starbud_coffe/services/user_service.dart';
import 'package:starbud_coffe/models/user_model.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final service = UserService();
  List<UserModel> users = [];
  final accentColor = const Color(0xFFAF7705);
  final primaryColor = const Color(0xFF6D4C41);

  String filter = 'semua';
  String sort = 'nama';
  String search = '';
  String? loadingUserId;

  TextEditingController searchController = TextEditingController();

  void loadUsers() async {
    final data = await service.getUsers();

    if (!mounted) return;

    setState(() {
      users = data;
    });
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info, color: Colors.white60, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                "Berhasil",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showInfoDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info, color: Colors.white60, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                "Info",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCustomDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showUserForm([UserModel? user]) {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: user?.username);
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();
    final emailController = TextEditingController();

    String selectedRole = user?.role ?? 'pegawai';
    bool isLoading = false;
    bool obscure = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: Colors.white,
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    user == null ? "Tambah User" : "Edit User",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    user == null
                                        ? Icons.person_add
                                        : Icons.edit,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  user == null
                                      ? "Tambah User Baru"
                                      : "Edit User",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Isi data dengan benar",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Informasi User",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: emailController,
                                          enabled: user == null,
                                          decoration: InputDecoration(
                                            labelText: "Email",
                                            labelStyle: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.email_outlined,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF9F9F9),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: accentColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          validator: (val) {
                                            if (user != null) return null;
                                            if (val == null || val.isEmpty)
                                              return "Wajib diisi";
                                            if (!RegExp(
                                              r'\S+@\S+\.\S+',
                                            ).hasMatch(val))
                                              return "Email tidak valid";
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                            labelText: "Username",
                                            labelStyle: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF9F9F9),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: accentColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          validator: (val) {
                                            if (val == null || val.isEmpty)
                                              return "Wajib diisi";
                                            if (val.length < 3)
                                              return "Minimal 3 karakter";
                                            if (val.length > 20)
                                              return "Maksimal 20 karakter";
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (user == null)
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: passController,
                                                obscureText: obscure,
                                                onChanged: (_) =>
                                                    setStateDialog(() {}),
                                                validator: (val) {
                                                  if (val == null ||
                                                      val.isEmpty)
                                                    return "Wajib diisi";
                                                  if (val.length < 6)
                                                    return "Minimal 6 karakter";
                                                  if (!RegExp(
                                                    r'[0-9]',
                                                  ).hasMatch(val))
                                                    return "Harus ada angka";
                                                  if (!RegExp(
                                                    r'[A-Z]',
                                                  ).hasMatch(val))
                                                    return "Harus ada huruf besar";
                                                  if (!RegExp(
                                                    r'[!@#$%^&*(),.?":{}|<>]',
                                                  ).hasMatch(val))
                                                    return "Harus ada simbol";
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  labelText: "Password",
                                                  labelStyle:
                                                      GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                  prefixIcon: const Icon(
                                                    Icons.lock_outline,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: Colors
                                                          .grey
                                                          .shade300,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: accentColor,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      obscure
                                                          ? Icons.visibility_off
                                                          : Icons.visibility,
                                                    ),
                                                    onPressed: () {
                                                      setStateDialog(() {
                                                        obscure = !obscure;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    confirmPassController,
                                                obscureText: obscureConfirm,
                                                onChanged: (_) =>
                                                    setStateDialog(() {}),
                                                validator: (val) {
                                                  if (val == null ||
                                                      val.isEmpty)
                                                    return "Wajib diisi";
                                                  if (val !=
                                                      passController.text)
                                                    return "Password tidak sama";
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  labelText: "Confirm Password",
                                                  labelStyle:
                                                      GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                  prefixIcon: const Icon(
                                                    Icons.lock_outline,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: Colors
                                                          .grey
                                                          .shade300,
                                                    ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: accentColor,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                                  suffixIcon: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (confirmPassController
                                                          .text
                                                          .isNotEmpty)
                                                        Icon(
                                                          confirmPassController
                                                                      .text ==
                                                                  passController
                                                                      .text
                                                              ? Icons.check
                                                              : Icons.close,
                                                          color:
                                                              confirmPassController
                                                                          .text ==
                                                                      passController
                                                                          .text
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                        ),
                                                      IconButton(
                                                        icon: Icon(
                                                          obscureConfirm
                                                              ? Icons
                                                                  .visibility_off
                                                              : Icons
                                                                  .visibility,
                                                        ),
                                                        onPressed: () {
                                                          setStateDialog(() {
                                                            obscureConfirm =
                                                                !obscureConfirm;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: LinearProgressIndicator(
                                            minHeight: 6,
                                            value: passController.text.isEmpty
                                                ? 0
                                                : passController.text.length < 6
                                                ? 0.3
                                                : passController.text.length <
                                                      10
                                                ? 0.6
                                                : 1,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              passController.text.length < 6
                                                  ? Colors.red
                                                  : passController
                                                          .text
                                                          .length <
                                                      10
                                                  ? Colors.orange
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: selectedRole,
                                    decoration: InputDecoration(
                                      labelText: "Role",
                                      labelStyle: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: ['admin', 'pegawai']
                                        .map(
                                          (r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(
                                              r,
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        selectedRole = val!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "* Pastikan data sudah benar sebelum disimpan",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    if (user == null)
                      TextButton(
                        onPressed: () {
                          final isEmpty =
                              emailController.text.isEmpty &&
                              nameController.text.isEmpty &&
                              passController.text.isEmpty &&
                              confirmPassController.text.isEmpty;

                          if (isEmpty) {
                            showInfoDialog("Tidak ada perubahan data");
                            return;
                          }

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.refresh, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Reset Form",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                "Semua input akan dihapus",
                                style: GoogleFonts.poppins(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Batal",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                  ),
                                  onPressed: () {
                                    if (mounted) Navigator.pop(context);

                                    setStateDialog(() {
                                      emailController.clear();
                                      nameController.clear();
                                      passController.clear();
                                      confirmPassController.clear();
                                      selectedRole = 'pegawai';
                                    });

                                    showSuccessDialog("Form berhasil direset");
                                  },
                                  child: Text(
                                    "Reset",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text("Reset", style: GoogleFonts.poppins()),
                      ),
                    TextButton(
                      onPressed: () {
                        final isDirty = user == null
                            ? emailController.text.isNotEmpty ||
                                  nameController.text.isNotEmpty ||
                                  passController.text.isNotEmpty ||
                                  confirmPassController.text.isNotEmpty
                            : nameController.text != user.username ||
                                  selectedRole != user.role;

                        if (!isDirty) {
                          if (mounted) Navigator.pop(context);
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Keluar?",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              "Data yang sudah diisi tidak akan tersimpan ",
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Batal",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Keluar",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text("Batal", style: GoogleFonts.poppins()),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        elevation: 6,
                        shadowColor: accentColor.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;

                              setStateDialog(() => isLoading = true);

                              try {
                                if (user != null) {
                                  final isSame =
                                      nameController.text == user.username &&
                                      selectedRole == user.role;

                                  if (isSame) {
                                    setStateDialog(() => isLoading = false);
                                    showInfoDialog("Tidak ada perubahan data");
                                    return;
                                  }
                                }

                                final username = nameController.text
                                    .trim()
                                    .toLowerCase();

                                final usernameExist = users.any(
                                  (u) =>
                                      u.username.toLowerCase() == username &&
                                      u.id != user?.id,
                                );

                                if (usernameExist) {
                                  showInfoDialog("Username sudah digunakan");
                                  setStateDialog(() => isLoading = false);
                                  return;
                                }
                                if (user == null) {
                                  await service.addUser(
                                    emailController.text.trim(),
                                    nameController.text.trim(),
                                    passController.text.trim(),
                                    selectedRole,
                                  );
                                  if (!mounted) return;

                                  loadUsers();

                                  Navigator.pop(context);

                                  showCustomDialog(
                                    title: "Berhasil",
                                    message: "User berhasil ditambahkan",
                                    icon: Icons.check_circle,
                                    color: accentColor,
                                  );
                                } else {
                                  await service.updateUser(
                                    user.id,
                                    nameController.text.trim(),
                                    selectedRole,
                                  );

                                  if (!mounted) return;

                                  loadUsers();

                                  Navigator.pop(context);

                                  showCustomDialog(
                                    title: "Berhasil",
                                    message: "User berhasil diupdate",
                                    icon: Icons.check_circle,
                                    color: accentColor,
                                  );
                                }
                              } on AuthException catch (e) {
                                if (!mounted) return;
                                showInfoDialog(e.message);
                              } on PostgrestException catch (e) {
                                if (!mounted) return;
                                showInfoDialog("Error database: ${e.message}");
                              } catch (e) {
                                if (!mounted) return;
                                showInfoDialog("Terjadi kesalahan");
                              } finally {
                                if (mounted) {
                                  setStateDialog(() => isLoading = false);
                                }
                              }
                            },
                      child: isLoading
                          ? Shimmer.fromColors(
                              baseColor: Colors.white.withOpacity(0.3),
                              highlightColor: Colors.white,
                              child: Text(
                                "Menyimpan...",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Text(
                              "Simpan",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
                if (isLoading)
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String title, int value, Color color) {
    String imageUrl = title == "Total"
        ? "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSTMGNCKPSTsNN4n1BwA9BWzBYbr6VKdVyGEQ&s"
        : title == "Aktif"
        ? "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQJY3FWNUJY_U31PXGRheakCDVavC_ht0gdWg&s"
        : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRtyaekrEjoiVlAPvU8DqjKkkakAimKuKaHKA&s";
    return Expanded(
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 90,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          title == "Total"
                              ? Icons.people
                              : title == "Aktif"
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$value",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _highlightText(String text, String search) {
    if (search.isEmpty) return [TextSpan(text: text)];

    final lowerText = text.toLowerCase();
    final lowerSearch = search.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerSearch, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      spans.add(TextSpan(text: text.substring(start, index)));

      spans.add(
        TextSpan(
          text: text.substring(index, index + search.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + search.length;
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((u) {
      final matchSearch = u.username.toLowerCase().contains(
        search.trim().toLowerCase(),
      );

      final matchFilter = filter == 'semua'
          ? true
          : filter == 'aktif'
          ? u.isActive
          : !u.isActive;

      return matchSearch && matchFilter;
    }).toList();

    if (sort == 'nama') {
      filteredUsers.sort(
        (a, b) => a.username.trim().toLowerCase().compareTo(
          b.username.trim().toLowerCase(),
        ),
      );
    } else if (sort == 'status') {
      filteredUsers.sort((a, b) {
        int statusCompare = (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);

        if (statusCompare != 0) return statusCompare;

        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Manajemen User",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16, bottom: 14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statCard("Total", users.length, Colors.black),
                  const SizedBox(width: 10),
                  _statCard(
                    "Aktif",
                    users.where((u) => u.isActive).length,
                    Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    "Nonaktif",
                    users.where((u) => !u.isActive).length,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: searchController,
                    onChanged: (val) {
                      setState(() {
                        search = val.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Search",
                      hintText: "Cari user...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  search = '';
                                  searchController.clear();
                                });
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        child: DropdownButtonFormField<String>(
                          value: sort,
                          decoration: InputDecoration(
                            labelText: "Sort",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'nama',
                              child: Text('Nama'),
                            ),
                            DropdownMenuItem(
                              value: 'status',
                              child: Text('Status'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => sort = val!);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        child: DropdownButtonFormField<String>(
                          value: filter,
                          decoration: InputDecoration(
                            labelText: "Filter",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'semua',
                              child: Text('Semua'),
                            ),
                            DropdownMenuItem(
                              value: 'aktif',
                              child: Text('Aktif'),
                            ),
                            DropdownMenuItem(
                              value: 'nonaktif',
                              child: Text('Nonaktif'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => filter = val!);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => showUserForm(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        "Tambah",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Daftar User",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Center(
                              child: Text(
                                "Status",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Text(
                                "Aksi",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filteredUsers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                search.isNotEmpty
                                    ? Icons.search_off
                                    : filter == 'nonaktif'
                                    ? Icons.block
                                    : Icons.people_outline,
                                size: 60,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              search.isNotEmpty
                                  ? "Data tidak ditemukan"
                                  : users.isEmpty
                                  ? "Belum ada user"
                                  : filter == 'nonaktif'
                                  ? "Tidak ada user nonaktif"
                                  : filter == 'aktif'
                                  ? "Tidak ada user aktif"
                                  : "Tidak ada data",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              search.isNotEmpty
                                  ? "Coba kata kunci lain"
                                  : users.isEmpty
                                  ? "Tambahkan user pertama kamu"
                                  : filter == 'nonaktif'
                                  ? "Semua user masih aktif"
                                  : filter == 'aktif'
                                  ? "Semua user sedang nonaktif"
                                  : "Belum ada data",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                elevation: 6,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  search = '';
                                  filter = 'semua';
                                  searchController.clear();
                                });
                              },
                              icon: const Icon(
                                Icons.refresh,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                "Reset",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredUsers.map((u) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: accentColor
                                            .withOpacity(0.1),
                                        child: Icon(
                                          Icons.person,
                                          color: accentColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                children: _highlightText(
                                                  u.username,
                                                  search,
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: u.role == 'admin'
                                                    ? Colors.red.withOpacity(0.1)
                                                    : Colors.blue.withOpacity(
                                                        0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                u.role,
                                                style: GoogleFonts.poppins(
                                                  color: u.role == 'admin'
                                                      ? Colors.red
                                                      : Colors.blue,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (loadingUserId == u.id)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: u.isActive,
                                          activeTrackColor: Colors.green
                                              .withOpacity(0.4),
                                          inactiveTrackColor:
                                              Colors.grey.shade300,
                                          onChanged: loadingUserId == u.id
                                              ? null
                                              : (val) async {
                                                  setState(
                                                    () => loadingUserId = u.id,
                                                  );

                                                  try {
                                                    if (u.role == 'admin' &&
                                                        !val) {
                                                      showCustomDialog(
                                                        title: "Info",
                                                        message:
                                                            "Admin tidak bisa dinonaktifkan",
                                                        icon: Icons.info,
                                                        color: accentColor,
                                                      );
                                                      return;
                                                    }

                                                    if (!val) {
                                                      showDialog(
                                                        context: context,
                                                        useRootNavigator: true,
                                                        builder: (_) => AlertDialog(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                              20,
                                                            ),
                                                          ),
                                                          title: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .warning_amber_rounded,
                                                                color: Colors
                                                                    .orange,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                "Nonaktifkan User?",
                                                                style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          content: Text(
                                                            "Yakin mau nonaktifkan ${u.username}?",
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                context,
                                                              ),
                                                              child: Text(
                                                                "Batal",
                                                                style:
                                                                    GoogleFonts.poppins(),
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    accentColor,
                                                              ),
                                                              onPressed: () async {
                                                                await service
                                                                    .deactivateUser(
                                                                  u.id,
                                                                );

                                                                if (!mounted)
                                                                  return;

                                                                loadUsers();
                                                                Navigator.pop(
                                                                  context,
                                                                );

                                                                showCustomDialog(
                                                                  title:
                                                                      "Berhasil",
                                                                  message:
                                                                      "User berhasil dinonaktifkan",
                                                                  icon: Icons
                                                                      .check_circle,
                                                                  color:
                                                                      accentColor,
                                                                );
                                                              },
                                                              child: Text(
                                                                "Nonaktifkan",
                                                                style: GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    } else {
                                                      await service
                                                          .activateUser(u.id);

                                                      if (!mounted) return;

                                                      loadUsers();

                                                      showCustomDialog(
                                                        title: "Berhasil",
                                                        message:
                                                            "User berhasil diaktifkan",
                                                        icon:
                                                            Icons.check_circle,
                                                        color: accentColor,
                                                      );
                                                    }
                                                  } finally {
                                                    setState(
                                                      () =>
                                                          loadingUserId = null,
                                                    );
                                                  }
                                                },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tooltip(
                                        message: "Edit User",
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit_square,
                                            size: 20,
                                          ),
                                          color: Colors.blue,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => showUserForm(u),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      FutureBuilder<bool>(
                                        future: service.isUserUsed(u.id),
                                        builder: (context, snapshot) {
                                          final isUsed =
                                              snapshot.data ?? false;

                                          return Tooltip(
                                            message: isUsed
                                                ? "User sudah dipakai di transaksi"
                                                : "Hapus User",
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 20,
                                              ),
                                              color: isUsed
                                                  ? Colors.grey
                                                  : Colors.red,
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: isUsed
                                                  ? null
                                                  : () async {
                                                      showDialog(
                                                        context: context,
                                                        builder: (_) => AlertDialog(
                                                          title: Text(
                                                            "Hapus User",
                                                            style: GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          content: Text(
                                                            "Yakin hapus ${u.username}?",
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                context,
                                                              ),
                                                              child: Text(
                                                                "Batal",
                                                                style: GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .grey[700],
                                                                ),
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .red, 
                                                                foregroundColor:
                                                                    Colors
                                                                        .white, 
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical:
                                                                      12,
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                                ),
                                                              ),
                                                              onPressed: () async {
                                                                await service
                                                                    .deleteUser(
                                                                  u.id,
                                                                );
                                                                if (!mounted)
                                                                  return;

                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                loadUsers();

                                                                showCustomDialog(
                                                                  title:
                                                                      "Berhasil",
                                                                  message:
                                                                      "User berhasil dihapus",
                                                                  icon: Icons
                                                                      .check_circle,
                                                                  color:
                                                                      accentColor,
                                                                );
                                                              },
                                                              child: Text(
                                                                "Hapus",
                                                                style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}