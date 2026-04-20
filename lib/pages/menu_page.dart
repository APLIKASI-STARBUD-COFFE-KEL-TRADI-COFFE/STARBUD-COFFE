import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:starbud_coffe/services/menu_service.dart';
import 'package:starbud_coffe/models/menu_model.dart';
import 'package:starbud_coffe/services/category_service.dart';
import 'package:starbud_coffe/services/recipe_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final service = MenuService();
  final searchController = TextEditingController();

  String formatRupiah(String value) {
    final number = int.tryParse(value.replaceAll('.', '')) ?? 0;
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number).replaceAll(',', '.');
  }

  String searchQuery = "";
  String selectedStatus = "Semua";
  String selectedCategory = "Semua";
  List<dynamic> categories = [];

  late bool isDarkMode;
  late Color rowColor;
  late Color backgroundColor;
  late Color iconEditColor;
  late Color iconDeleteColor;
  late Color switchActiveColor;
  late Future<List<MenuModel>> _menuFuture;

  @override
  void initState() {
    super.initState();
    selectedStatus = "Semua";
    selectedCategory = "Semua";
    searchQuery = "";
    _menuFuture = service.getMenus();
    Future.microtask(() {
      loadCategories();
    });
  }

  Map<String, bool> recipeMap = {};
  bool isLoadingRecipe = true;

  bool isRecipeLoaded = false;

  void loadCategories() async {
    final data = await CategoryService().getCategories();
    setState(() {
      categories = data;
    });
  }

  void showMenuDialog({MenuModel? menu}) async {
    final nameController = TextEditingController(text: menu?.name ?? "");
    final priceController = TextEditingController(
      text: menu?.price.toString() ?? "",
    );
    final stockController = TextEditingController(
      text: menu?.stock.toString() ?? "",
    );

    final initialName = menu?.name ?? "";
    final initialPrice = menu?.price.toString() ?? "";
    final initialStock = menu?.stock.toString() ?? "";
    final initialCategory = menu?.categoryId;

    final categoryService = CategoryService();
    final menus = await service.getMenus();
    final categories = await categoryService.getCategories();

    String? selectedCategoryId = menu?.categoryId;
    String? imageUrl;

    if (menu != null) {
      imageUrl = menu.imageUrl;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        String? nameError;
        String? priceError;
        String? stockError;
        String? categoryError;

        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                menu == null ? "Tambah Menu" : "Edit Menu",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        "Preview Gambar",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      if (imageUrl != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (imageUrl!.isNotEmpty)
                                ? Image.network(
                                    "${imageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}",
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.image, size: 50),
                                    ),
                                  ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final file = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );

                                if (file != null) {
                                  final bytes = await file.readAsBytes();

                                  if (bytes.length > 1048576) {
                                    showNiceDialog(
                                      title: "Gagal",
                                      message: "Ukuran gambar maksimal 1 MB",
                                      icon: Icons.error,
                                      color: Colors.red,
                                    );
                                    return;
                                  }

                                  final ext = file.name
                                      .split('.')
                                      .last
                                      .toLowerCase();
                                  if (!['jpg', 'jpeg', 'png'].contains(ext)) {
                                    showNiceDialog(
                                      title: "Gagal",
                                      message:
                                          "Format harus JPG, JPEG, atau PNG",
                                      icon: Icons.error,
                                      color: Colors.red,
                                    );
                                    return;
                                  }

                                  final fileName =
                                      '${DateTime.now().millisecondsSinceEpoch}.$ext';
                                  if (imageUrl != null &&
                                      imageUrl!.contains('menu-images')) {
                                    final oldPath = imageUrl!
                                        .split('/menu-images/')
                                        .last;
                                    await Supabase.instance.client.storage
                                        .from('menu-images')
                                        .remove([oldPath]);
                                  }

                                  await Supabase.instance.client.storage
                                      .from('menu-images')
                                      .uploadBinary(fileName, bytes);

                                  final publicUrl = Supabase
                                      .instance
                                      .client
                                      .storage
                                      .from('menu-images')
                                      .getPublicUrl(fileName);

                                  setStateDialog(() {
                                    imageUrl = publicUrl;
                                  });
                                }
                              },
                              icon: const Icon(Icons.upload),
                              label: const Text("Upload"),
                            ),
                          ),

                          const SizedBox(width: 8),

                          if (imageUrl != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setStateDialog(() {
                                  imageUrl = null;
                                });
                              },
                            ),
                        ],
                      ),

                      const SizedBox(width: 8),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Nama Menu",
                          errorText: nameError,
                        ),
                      ),

                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Harga",
                          prefixText: "Rp ",
                          errorText: priceError,
                        ),
                      ),

                      TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Stok",
                          errorText: stockError,
                        ),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        hint: const Text("Pilih Kategori"),
                        decoration: InputDecoration(
                          labelText: "Kategori",
                          errorText: categoryError,
                        ),
                        items: categories.map<DropdownMenuItem<String>>((c) {
                          final isDisabled = !c.isActive;

                          return DropdownMenuItem(
                            value: c.id,
                            enabled: !isDisabled,
                            child: Text(
                              c.name,
                              style: TextStyle(
                                color: isDisabled ? Colors.grey : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setStateDialog(() {
                            selectedCategoryId = value;
                            categoryError = null;
                          });
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final currentPrice = priceController.text.replaceAll(
                      '.',
                      '',
                    );

                    final initialImage = menu?.imageUrl;

                    final isChanged =
                        nameController.text != initialName ||
                        currentPrice != initialPrice ||
                        stockController.text != initialStock ||
                        selectedCategoryId != initialCategory ||
                        imageUrl != initialImage;

                    if (!isChanged) {
                      Navigator.pop(context);
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Keluar?",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            "Perubahan tidak disimpan, yakin mau keluar?",
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Tidak",
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Ya, keluar",
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text("Batal", style: GoogleFonts.poppins()),
                ),

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setStateDialog(() {
                            isSaving = true;
                          });
                          bool isValid = true;

                          nameError = null;
                          priceError = null;
                          stockError = null;
                          categoryError = null;

                          if (nameController.text.trim().isEmpty) {
                            nameError = "Nama menu wajib diisi";
                            isValid = false;
                          } else if (nameController.text.trim().length < 3) {
                            nameError = "Minimal 3 karakter";
                            isValid = false;
                          }

                          final existing = menus.any(
                            (m) =>
                                m.name.toLowerCase().trim() ==
                                    nameController.text.toLowerCase().trim() &&
                                m.id != menu?.id,
                          );

                          if (existing) {
                            nameError = "Nama menu sudah digunakan";
                            isValid = false;
                          }

                          String cleanPrice = priceController.text
                              .replaceAll('.', '')
                              .trim();

                          if (cleanPrice.isEmpty) {
                            priceError = "Harga wajib diisi";
                            isValid = false;
                          } else if (int.tryParse(cleanPrice) == null) {
                            priceError = "Harga harus angka";
                            isValid = false;
                          } else if (int.parse(cleanPrice) <= 0) {
                            priceError = "Harga harus lebih dari 0";
                            isValid = false;
                          } else if (int.parse(cleanPrice) > 500000) {
                            priceError = "Maksimal harga 500.000";
                            isValid = false;
                          }

                          if (stockController.text.trim().isEmpty) {
                            stockError = "Stok wajib diisi";
                            isValid = false;
                          } else if (int.tryParse(stockController.text) ==
                              null) {
                            stockError = "Stok harus angka";
                            isValid = false;
                          } else if (int.parse(stockController.text) < 0) {
                            stockError = "Stok tidak boleh minus";
                            isValid = false;
                          } else if (int.parse(stockController.text) > 1000) {
                            stockError = "Maksimal stok 1000";
                            isValid = false;
                          }

                          if (selectedCategoryId == null) {
                            categoryError = "Pilih kategori dulu";
                            isValid = false;
                          }

                          if (!isValid) {
                            setStateDialog(() {});
                            return;
                          }

                          final currentPrice = priceController.text.replaceAll(
                            '.',
                            '',
                          );

                          final initialImage = menu?.imageUrl;

                          final isChanged =
                              nameController.text != initialName ||
                              currentPrice != initialPrice ||
                              stockController.text != initialStock ||
                              selectedCategoryId != initialCategory ||
                              imageUrl != initialImage;

                          if (menu != null && !isChanged) {
                            showNiceDialog(
                              title: "Tidak ada perubahan",
                              message: "Data tidak mengalami perubahan",
                              icon: Icons.info,
                              color: Colors.orange,
                            );
                            return;
                          }

                          final name = nameController.text.trim();
                          final price = int.parse(
                            priceController.text.replaceAll('.', '').trim(),
                          );
                          final stock = int.parse(stockController.text.trim());

                          try {
                            if (menu == null) {
                              await service.addMenu(
                                name,
                                price,
                                stock,
                                selectedCategoryId!,
                                imageUrl,
                              );
                            } else {
                              await service.updateMenu(
                                menu.id,
                                name,
                                price,
                                stock,
                                selectedCategoryId!,
                                imageUrl,
                              );
                            }
                          } catch (e) {
                            setStateDialog(() {
                              isSaving = false;
                            });

                            showNiceDialog(
                              title: "Gagal",
                              message: "Terjadi kesalahan, coba lagi",
                              icon: Icons.error,
                              color: Colors.red,
                            );
                            return;
                          }

                          setStateDialog(() {
                            isSaving = false;
                          });

                          if (!mounted) return;

                          Navigator.pop(context);

                          showNiceDialog(
                            title: "Berhasil",
                            message: menu == null
                                ? "Menu berhasil ditambahkan"
                                : "Menu berhasil diperbarui",
                            icon: Icons.check_circle,
                            color: Colors.green,
                          );
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text("Simpan", style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showAddRecipeDialog(String menuId) async {
    List<Map<String, dynamic>> selectedItems = [
      {
        "stockId": null,
        "qtyController": TextEditingController(),
        "isOptional": false,
        "stockError": null,
        "qtyError": null,
      },
    ];

    final existingRecipes = await RecipeService().getRecipesByMenu(menuId);

    final usedStockIds = existingRecipes.map((e) => e['stocks']['id']).toList();

    final stocks = await Supabase.instance.client.from('stocks').select();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Tambah Bahan",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...selectedItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: item["stockId"],
                                hint: Text(
                                  "Pilih Bahan",
                                  style: GoogleFonts.poppins(),
                                ),
                                decoration: InputDecoration(
                                  errorText: item["stockError"],
                                ),
                                items: stocks.map<DropdownMenuItem<String>>((
                                  s,
                                ) {
                                  final isUsed =
                                      usedStockIds.contains(s['id']) ||
                                      selectedItems.any(
                                        (e) =>
                                            e["stockId"] == s['id'] &&
                                            e != item,
                                      );

                                  return DropdownMenuItem(
                                    value: isUsed ? null : s['id'],
                                    enabled: !isUsed,
                                    child: Text(
                                      s['name'],
                                      style: GoogleFonts.poppins(
                                        color: isUsed
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    item["stockId"] = val;
                                    item["stockError"] = null;
                                  });
                                },
                              ),

                              const SizedBox(height: 8),

                              TextField(
                                controller: item["qtyController"],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Quantity",
                                  errorText: item["qtyError"],
                                ),
                                onChanged: (val) {
                                  String clean = val.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );

                                  item["qtyController"].value =
                                      TextEditingValue(
                                        text: clean,
                                        selection: TextSelection.collapsed(
                                          offset: clean.length,
                                        ),
                                      );

                                  setStateDialog(() {
                                    item["qtyError"] = null;
                                  });
                                },
                              ),

                              SwitchListTile(
                                value: item["isOptional"],
                                title: Text(
                                  item["isOptional"] ? "Optional" : "Wajib",
                                  style: GoogleFonts.poppins(),
                                ),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    item["isOptional"] = val;
                                  });
                                },
                              ),

                              if (selectedItems.length > 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setStateDialog(() {
                                        selectedItems.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 10),

                      ElevatedButton.icon(
                        onPressed: () {
                          setStateDialog(() {
                            selectedItems.add({
                              "stockId": null,
                              "qtyController": TextEditingController(),
                              "isOptional": false,
                              "stockError": null,
                              "qtyError": null,
                            });
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          "Tambah Lagi",
                          style: GoogleFonts.poppins(),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    final isFilled = selectedItems.any(
                      (item) =>
                          item["stockId"] != null ||
                          item["qtyController"].text.isNotEmpty,
                    );

                    if (!isFilled) {
                      Navigator.pop(context);
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          "Keluar?",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "Data belum disimpan, yakin mau keluar?",
                          style: GoogleFonts.poppins(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Tidak", style: GoogleFonts.poppins()),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text("Ya", style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text("Batal", style: GoogleFonts.poppins()),
                ),

                ElevatedButton(
                  onPressed: () async {
                    bool isValid = true;

                    for (var item in selectedItems) {
                      item["stockError"] = null;
                      item["qtyError"] = null;

                      if (item["stockId"] == null) {
                        item["stockError"] = "Pilih bahan";
                        isValid = false;
                      }

                      final qty = item["qtyController"].text;

                      if (qty.isEmpty) {
                        item["qtyError"] = "Wajib diisi";
                        isValid = false;
                      } else if (int.tryParse(qty) == null ||
                          int.parse(qty) <= 0) {
                        item["qtyError"] = "Harus angka > 0";
                        isValid = false;
                      }
                    }

                    if (!isValid) {
                      setStateDialog(() {});
                      return;
                    }

                    final duplicate = selectedItems
                        .map((e) => e["stockId"])
                        .toList();

                    if (duplicate.length != duplicate.toSet().length) {
                      showNiceDialog(
                        title: "Gagal",
                        message: "Tidak boleh memilih bahan yang sama",
                        icon: Icons.error,
                        color: Colors.red,
                      );
                      return;
                    }

                    for (var item in selectedItems) {
                      await RecipeService().addRecipe(
                        menuId,
                        item["stockId"],
                        int.parse(item["qtyController"].text),
                        item["isOptional"],
                      );
                    }

                    if (!mounted) return;

                    Navigator.pop(context);

                    showNiceDialog(
                      title: "Berhasil",
                      message: "Bahan berhasil ditambahkan",
                      icon: Icons.check_circle,
                      color: Colors.green,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAF7705),
                  ),
                  child: Text("Simpan", style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showEditRecipeDialog(Map r) async {
    final qtyController = TextEditingController(text: r['quantity'].toString());
    final initialQty = r['quantity'].toString();
    final initialOptional = r['is_optional'] ?? false;
    bool isOptional = r['is_optional'] ?? false;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit_square, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    "Edit Bahan",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quantity"),
                  ),

                  const SizedBox(height: 10),

                  SwitchListTile(
                    value: isOptional,
                    title: Text(
                      isOptional
                          ? "Optional (customer bisa pilih)"
                          : "Wajib (selalu digunakan)",
                    ),
                    onChanged: (val) {
                      setStateDialog(() {
                        isOptional = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final isChanged =
                        qtyController.text != initialQty ||
                        isOptional != initialOptional;

                    if (!isChanged) {
                      Navigator.pop(context);
                      return;
                    }

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Keluar?",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          "Perubahan tidak disimpan, yakin mau keluar?",
                          style: GoogleFonts.poppins(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Tidak", style: GoogleFonts.poppins()),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text("Ya", style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text("Batal", style: GoogleFonts.poppins()),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (qtyController.text.isEmpty) {
                      showNiceDialog(
                        title: "Gagal",
                        message: "Quantity wajib diisi",
                        icon: Icons.error,
                        color: Colors.red,
                      );
                      return;
                    }

                    if (int.tryParse(qtyController.text) == null ||
                        int.parse(qtyController.text) <= 0) {
                      showNiceDialog(
                        title: "Gagal",
                        message: "Quantity harus angka dan lebih dari 0",
                        icon: Icons.error,
                        color: Colors.red,
                      );
                      return;
                    }

                    final isChanged =
                        qtyController.text != initialQty ||
                        isOptional != initialOptional;

                    if (!isChanged) {
                      showNiceDialog(
                        title: "Tidak ada perubahan",
                        message: "Data tidak mengalami perubahan",
                        icon: Icons.info,
                        color: Colors.orange,
                      );
                      return;
                    }

                    await Supabase.instance.client
                        .from('recipes')
                        .update({
                          'quantity': int.parse(qtyController.text),
                          'is_optional': isOptional,
                        })
                        .eq('id', r['id']);

                    if (!mounted) return;

                    Navigator.pop(context);

                    showNiceDialog(
                      title: "Berhasil",
                      message: "Bahan berhasil diperbarui",
                      icon: Icons.check_circle,
                      color: Colors.green,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAF7705),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Simpan", style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteMenu(MenuModel m) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                "Hapus Menu",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          content: Text(
            "Menu '${m.name}' akan dihapus.\nAksi ini tidak bisa dibatalkan",
            style: GoogleFonts.poppins(height: 1.5),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal", style: GoogleFonts.poppins()),
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.delete),
              label: Text("Hapus", style: GoogleFonts.poppins()),
              onPressed: () async {
                await service.deleteMenu(m.id);

                Navigator.pop(context);

                showNiceDialog(
                  title: "Berhasil",
                  message: "Menu '${m.name}' berhasil dihapus",
                  icon: Icons.check_circle,
                  color: Colors.green,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void showRecipeDetail(MenuModel menu) async {
    List recipes = await RecipeService().getRecipesByMenu(menu.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            Future<void> refreshRecipes() async {
              recipes = await RecipeService().getRecipesByMenu(menu.id);
              setStateSheet(() {});
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E9E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.brown.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),

                      Text(
                        "Detail Resep",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4E342E),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  Text(
                    menu.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.brown,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (recipes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Belum ada resep",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  else
                    ...recipes.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F1E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.brown.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['stocks']['name'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4E342E),
                                    ),
                                  ),

                                  Text(
                                    "Qty: ${r['quantity']}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF4E342E),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: r['is_optional'] == true
                                          ? Colors.orange.withOpacity(0.15)
                                          : Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r['is_optional'] == true
                                          ? "Optional"
                                          : "Wajib",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: r['is_optional'] == true
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () async {
                                await showEditRecipeDialog(r);

                                await refreshRecipes();
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Hapus Bahan",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      "Bahan '${r['stocks']['name']}' akan dihapus",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          "Batal",
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          "Hapus",
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                await Supabase.instance.client
                                    .from('recipes')
                                    .delete()
                                    .eq('id', r['id']);

                                await refreshRecipes();

                                showNiceDialog(
                                  title: "Berhasil",
                                  message: "Bahan berhasil dihapus",
                                  icon: Icons.check_circle_rounded,
                                  color: Colors.green,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await showAddRecipeDialog(menu.id);

                        await refreshRecipes();
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Tambah Resep",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4C41),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showNiceDialog({
    required String title,
    required String message,
    required IconData icon,
    Color color = Colors.orange,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryBadge(String? category) {
    final name = category ?? "-";
    final color = _getCategoryColor(name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey.withOpacity(0.4)),

          const SizedBox(height: 16),

          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                searchQuery = "";
                selectedStatus = "Semua";
                selectedCategory = "Semua";

                searchController.clear();
              });

              showNiceDialog(
                title: "Reset Berhasil",
                message: "Pencarian & filter sudah dikembalikan",
                icon: Icons.refresh,
                color: Colors.blue,
              );
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              "Reset",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAF7705),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.red,
      Colors.indigo,
    ];
    final index = category.hashCode % colors.length;
    return colors[index.abs()];
  }

  Widget _menuCard(MenuModel m) {
    final hasRecipe = m.hasRecipe;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        color: rowColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: (m.imageUrl != null && m.imageUrl!.isNotEmpty)
                      ? Image.network(m.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, size: 40),
                          ),
                        ),
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _actionIcon(
                      icon: Icons.edit,
                      color: iconEditColor,
                      onTap: () => showMenuDialog(menu: m),
                    ),
                    const SizedBox(width: 6),
                    _actionIcon(
                      icon: Icons.delete,
                      color: hasRecipe ? Colors.grey : iconDeleteColor,
                      onTap: hasRecipe ? null : () => _confirmDeleteMenu(m),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF2E2E2E),
                          ),
                        ),
                      ),

                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: m.status,
                          activeColor: switchActiveColor,
                          onChanged: hasRecipe
                              ? (val) async {
                                  if (!val) {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        title: Text(
                                          "Nonaktifkan Menu",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        content: Text(
                                          "Menu '${m.name}' akan dinonaktifkan.",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              "Batal",
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              "Nonaktifkan",
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;
                                  }

                                  await service.updateStatus(m.id, val);

                                  setState(() {
                                    _menuFuture = service.getMenus();
                                  });
                                  showNiceDialog(
                                    title: "Berhasil",
                                    message: val
                                        ? "Menu berhasil diaktifkan"
                                        : "Menu berhasil dinonaktifkan",
                                    icon: Icons.check_circle,
                                    color: Colors.green,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: m.status
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.status ? "Aktif" : "Nonaktif",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: m.status ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Rp ${formatRupiah(m.price.toString())}",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFAF7705),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    "Stok ${m.stock}",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 2),

                  _categoryBadge(m.categoryName),

                  const Spacer(),

                  Center(
                    child: GestureDetector(
                      onTap: hasRecipe ? () => showRecipeDetail(m) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6D4C41).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hasRecipe ? "Lihat Resep" : "Belum ada resep",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: hasRecipe ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    rowColor = isDarkMode ? const Color(0xFF323232) : Colors.white;
    backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    iconEditColor = isDarkMode ? const Color(0xFFAF7705) : Colors.blue;
    iconDeleteColor = isDarkMode ? Colors.red[300]! : Colors.red;
    switchActiveColor = isDarkMode ? Colors.greenAccent : Colors.green;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daftar Menu",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => showMenuDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAF7705),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      "Tambah",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Column(
            children: [
              TextField(
                controller: searchController,
                style: GoogleFonts.poppins(color: textColor),
                decoration: InputDecoration(
                  hintText: "Cari menu...",
                  hintStyle: GoogleFonts.poppins(color: subtitleColor),
                  prefixIcon: Icon(Icons.search, color: subtitleColor),

                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              searchQuery = "";
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: "Status Menu",
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: ["Semua", "Aktif", "Nonaktif"]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, style: GoogleFonts.poppins()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: "Semua",
                          child: Text("Semua"),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.name, style: GoogleFonts.poppins()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: FutureBuilder<List<MenuModel>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final menus = snapshot.data!;
                if (menus.isEmpty) {
                  return _buildEmptyState(
                    title: "Belum ada menu",
                    subtitle: "Tambahkan menu pertama Anda",
                    icon: Icons.add_to_photos_outlined,
                  );
                }

                final query = searchQuery.toLowerCase();

                final filteredMenus = menus.where((m) {
                  final matchSearch = m.name.toLowerCase().contains(query);

                  final matchStatus =
                      selectedStatus == "Semua" ||
                      (selectedStatus == "Aktif" && m.status == true) ||
                      (selectedStatus == "Nonaktif" && !m.status);

                  final matchCategory =
                      selectedCategory == "Semua" ||
                      (m.categoryName != null &&
                          m.categoryName!.toLowerCase().trim().contains(
                            selectedCategory.toLowerCase().trim(),
                          ));

                  return matchSearch && matchStatus && matchCategory;
                }).toList();

                if (filteredMenus.isEmpty) {
                  return _buildEmptyState(
                    title: "Menu tidak ditemukan",
                    subtitle: "Coba ubah kata kunci atau filter",
                    icon: Icons.search_off_rounded,
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${filteredMenus.length} items",
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount;

                          if (constraints.maxWidth < 600) {
                            crossAxisCount = 2;
                          } else if (constraints.maxWidth < 1000) {
                            crossAxisCount = 3;
                          } else {
                            crossAxisCount = 4;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredMenus.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  mainAxisExtent: 320,
                                ),
                            itemBuilder: (context, index) {
                              final m = filteredMenus[index];
                              return _menuCard(m);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
