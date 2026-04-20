import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:starbud_coffe/models/category_model.dart';
import 'package:starbud_coffe/services/category_service.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Color primaryColor = const Color(0xFFAF7705);
  final Color backgroundColor = Colors.white;

  String searchQuery = "";
  String selectedStatus = "Semua";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Manajemen Kategori",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  "Tambah Kategori",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    searchQuery = val.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Cari kategori...",
                  prefixIcon: const Icon(Icons.search),

                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              searchQuery = "";
                              _searchController.clear();
                            });
                          },
                        )
                      : null,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: ["Semua", "Aktif", "Nonaktif"].map((status) {
                  final isSelected = selectedStatus == status;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedStatus = status;
                        });
                      },
                      selectedColor: primaryColor,
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 15),
          Divider(color: Colors.grey.shade200, thickness: 1),

          Expanded(
            child: FutureBuilder<List<CategoryModel>>(
              future: _categoryService.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError)
                  return Center(child: Text("Error: ${snapshot.error}"));

                final categories = (snapshot.data ?? []).where((c) {
                  final matchSearch = c.name.toLowerCase().contains(
                    searchQuery,
                  );

                  final matchStatus = selectedStatus == "Semua"
                      ? true
                      : selectedStatus == "Aktif"
                      ? c.isActive
                      : !c.isActive;

                  return matchSearch && matchStatus;
                }).toList();

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),

                        Text(
                          searchQuery.isNotEmpty
                              ? "Kategori tidak ditemukan"
                              : "Tidak ada kategori",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          searchQuery.isNotEmpty
                              ? "Coba kata kunci lain"
                              : "Belum ada data kategori",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 15),

                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              searchQuery = "";
                              selectedStatus = "Semua";
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            "Reset",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 5),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final c = categories[index];

                    return FutureBuilder<bool>(
                      future: _categoryService.isCategoryUsed(c.id),
                      builder: (context, snap) {
                        final isUsed = snap.data ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.isActive
                                ? Colors.white
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.category, color: primaryColor),

                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Opacity(
                                      opacity: c.isActive ? 1 : 0.5,
                                      child: Text(
                                        c.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      c.isActive ? "Aktif" : "Nonaktif",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: c.isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Switch(
                                value: c.isActive,
                                activeColor: primaryColor,
                                onChanged: (val) async {
                                  if (!val) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text("Nonaktifkan Kategori"),
                                          ],
                                        ),
                                        content: Text(
                                          "Kategori '${c.name}' akan dinonaktifkan.\nMenu yang memakai kategori ini bisa ikut terdampak.\n\nLanjutkan?",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text("Batal"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text("Nonaktifkan"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;
                                  }

                                  await _categoryService.updateStatus(
                                    c.id,
                                    val,
                                  );
                                  _refreshData();

                                  showDialog(
                                    context: this.context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text("Berhasil"),
                                      content: Text(
                                        val
                                            ? "Kategori berhasil diaktifkan"
                                            : "Kategori berhasil dinonaktifkan",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogContext),
                                          child: const Text("OK"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.edit_square),
                                onPressed: () =>
                                    _showCategoryDialog(category: c),
                              ),

                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: isUsed ? Colors.grey : Colors.red,
                                ),
                                onPressed: isUsed
                                    ? null
                                    : () => _confirmDelete(c),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({CategoryModel? category}) {
    bool isEdit = category != null;
    String initialName = category?.name ?? "";
    if (isEdit) _categoryController.text = category.name;

    showDialog(
      context: this.context,
      builder: (context) {
        bool isSubmitted = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                isEdit ? "Update Kategori" : "Tambah Kategori",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: TextField(
                controller: _categoryController,
                onChanged: (_) {
                  setStateDialog(() {});
                },
                decoration: InputDecoration(
                  hintText: "Nama Kategori",
                  errorText: isSubmitted
                      ? _categoryController.text.trim().isEmpty
                            ? "Nama kategori wajib diisi"
                            : _categoryController.text.trim().length < 3
                            ? "Minimal 3 karakter"
                            : null
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final input = _categoryController.text.trim();

                    if (input.isNotEmpty && input != initialName) {
                      showDialog(
                        context: this.context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Batalkan?"),
                          content: const Text(
                            "Data belum disimpan. Yakin ingin keluar?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("Tidak"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                _categoryController.clear();
                              },
                              child: const Text("Ya"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Batal"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    setStateDialog(() {
                      isSubmitted = true;
                    });

                    final input = _categoryController.text.trim().toLowerCase();

                    final isExist = await _categoryService.isCategoryNameExist(
                      input,
                    );

                    if (isExist && input != initialName) {
                      showDialog(
                        context: this.context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Gagal"),
                          content: const Text("Nama kategori sudah digunakan"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    if (input.isEmpty) return;

                    if (isEdit && input == initialName) {
                      showDialog(
                        context: this.context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Tidak ada perubahan"),
                          content: const Text(
                            "Nama kategori tidak mengalami perubahan.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    if (isEdit) {
                      await _categoryService.updateCategory(category.id, input);
                    } else {
                      await _categoryService.addCategory(input);
                    }

                    if (!mounted) return;

                    Navigator.pop(context);
                    _categoryController.clear();
                    _refreshData();

                    showDialog(
                      context: this.context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text("Berhasil"),
                        content: Text(
                          isEdit
                              ? "Kategori berhasil diperbarui"
                              : "Kategori berhasil ditambahkan",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text(
                    "Simpan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: this.context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Kategori"),
        content: Text(
          "Apakah kamu yakin ingin menghapus kategori '${category.name}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _categoryService.deleteCategory(category.id);

              if (!mounted) return;

              Navigator.pop(context);
              _refreshData();

              showDialog(
                context: this.context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Berhasil"),
                  content: const Text("Kategori berhasil dihapus"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}
