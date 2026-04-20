import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:starbud_coffe/models/menu_model.dart';
import 'package:starbud_coffe/services/menu_service.dart';
import 'package:starbud_coffe/services/order_service.dart';
import 'package:starbud_coffe/models/category_model.dart';
import 'package:starbud_coffe/services/category_service.dart';

class TransaksiPage extends StatefulWidget {
  final String userId;
  const TransaksiPage({super.key, required this.userId});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final menuService = MenuService();
  final orderService = OrderService();
  final categoryService = CategoryService();
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  late Stream<List<MenuModel>> menuStream;
  List<Map<String, dynamic>> cart = [];
  late Stream<List<CategoryModel>> categoryStream;
  String selectedCategoryId = "all";
  bool isLoading = false;

  List<MenuModel> initialMenus = [];
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    loadInitialMenus();
    menuStream = menuService.streamMenus();
    categoryStream = categoryService.streamCategories();
  }

  Future<void> loadInitialMenus() async {
    final data = await menuService.getMenus();

    setState(() {
      initialMenus = data;
      isLoaded = true;
    });
  }

  Future<bool> isStockSufficient(
    int requestedQty,
    List<Map<String, dynamic>> selectedRecipe,
  ) async {
    for (var item in selectedRecipe) {
      final stockData = item['stocks'];
      double currentStock =
          double.tryParse(stockData['quantity'].toString()) ?? 0;
      double needPerItem = double.tryParse(item['quantity'].toString()) ?? 0;

      if (currentStock < (needPerItem * requestedQty)) {
        _showErrorSnackBar("Stok ${stockData['name']} tidak mencukupi!");
        return false;
      }
    }
    return true;
  }

  bool isStockLow(List<Map<String, dynamic>> recipe) {
    for (var item in recipe) {
      final stock = item['stocks'];
      double current = double.tryParse(stock['quantity'].toString()) ?? 0;

      if (current < 5) {
        return true;
      }
    }
    return false;
  }

  bool isStockSufficientSync(List<Map<String, dynamic>> recipe) {
    for (var item in recipe) {
      final stock = item['stocks'];
      double current = double.tryParse(stock['quantity'].toString()) ?? 0;

      double needed = double.tryParse(item['quantity'].toString()) ?? 0;

      if (current < needed) return false;
    }
    return true;
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ $message"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void validateCartStock(List<MenuModel> menus) {
    for (int i = cart.length - 1; i >= 0; i--) {
      final item = cart[i];

      final menuIndex = menus.indexWhere((m) => m.id == item['id']);

      if (menuIndex == -1) continue;

      final menu = menus[menuIndex];

      if (!menu.status) {
        _showErrorSnackBar("${item['name']} sudah tidak tersedia");
        setState(() => cart.removeAt(i));
        continue;
      }
    }
  }

  void showMenuDetail(MenuModel menu) async {
    List<Map<String, dynamic>> recipeData = await menuService.getRecipeForMenu(
      menu.id,
    );

    for (var item in recipeData) {
      item['is_selected'] = !(item['is_optional'] ?? false);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isOutOfStock = !isStockSufficientSync(
              recipeData.where((r) => r['is_selected'] == true).toList(),
            );
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          image: DecorationImage(
                            image:
                                (menu.imageUrl != null &&
                                    menu.imageUrl!.isNotEmpty)
                                ? NetworkImage(menu.imageUrl!)
                                : const NetworkImage(
                                    "https://via.placeholder.com/300x200",
                                  ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  menu.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "Rp ${menu.price}",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFAF7705),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Penyesuaian Resep:",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            "Centang bahan yang ingin digunakan",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: recipeData.isEmpty
                                ? const Center(
                                    child: Text(
                                      "Menu ini tidak memiliki data resep.",
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: recipeData.length,
                                    itemBuilder: (context, index) {
                                      final item = recipeData[index];
                                      final stock = item['stocks'];
                                      final bool isOptional =
                                          item['is_optional'] ?? false;

                                      final unit = stock['unit'] ?? '';
                                      final stockQty = stock['quantity'] ?? 0;

                                      final currentStock =
                                          double.tryParse(
                                            stock['quantity'].toString(),
                                          ) ??
                                          0;
                                      final needed =
                                          double.tryParse(
                                            item['quantity'].toString(),
                                          ) ??
                                          0;

                                      return CheckboxListTile(
                                        activeColor: const Color(0xFFAF7705),
                                        title: Text(
                                          stock['name'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: currentStock <= 0
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Kebutuhan: ${item['quantity']} $unit",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              "Stok tersedia: $stockQty $unit",
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),

                                            if (currentStock <= 0)
                                              Text(
                                                "Stok habis",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else if (currentStock < needed)
                                              Text(
                                                "Stok tidak cukup (butuh $needed $unit)",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                        value: item['is_selected'],
                                        onChanged:
                                            (isOptional &&
                                                currentStock >= needed)
                                            ? (bool? val) {
                                                setModalState(() {
                                                  item['is_selected'] =
                                                      val ?? false;
                                                });
                                              }
                                            : null,
                                        secondary: Icon(
                                          isOptional
                                              ? Icons.tune
                                              : Icons.push_pin,
                                          color: isOptional
                                              ? Colors.blueGrey
                                              : Colors.orange,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 10),

                          if (isStockLow(recipeData) && !isOutOfStock)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Beberapa bahan hampir habis",
                                      style: GoogleFonts.poppins(
                                        color: Colors.orange[800],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isOutOfStock
                                  ? null
                                  : () async {
                                      List<Map<String, dynamic>>
                                      selectedRecipe = recipeData
                                          .where(
                                            (r) => r['is_selected'] == true,
                                          )
                                          .toList();

                                      bool enough = await isStockSufficient(
                                        1,
                                        selectedRecipe,
                                      );

                                      if (enough) {
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        addToCart(menu, selectedRecipe);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAF7705),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                isOutOfStock
                                    ? "BAHAN TIDAK TERSEDIA"
                                    : "TAMBAHKAN KE PESANAN",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
          },
        );
      },
    );
  }

  void addToCart(MenuModel menu, List<Map<String, dynamic>> selectedRecipe) {
    setState(() {
      cart.add({
        'id': menu.id,
        'name': menu.name,
        'price': menu.price,
        'qty': 1,
        'selected_recipe': selectedRecipe,
      });
    });
  }

  void increaseQty(int index) async {
    final item = cart[index];
    bool enough = await isStockSufficient(
      item['qty'] + 1,
      item['selected_recipe'],
    );
    if (enough) {
      setState(() => cart[index]['qty']++);
    }
  }

  void decreaseQty(int index) {
    setState(() {
      if (cart[index]['qty'] > 1) {
        cart[index]['qty']--;
      } else {
        cart.removeAt(index);
      }
    });
  }

  int get total =>
      cart.fold(0, (sum, item) => sum + (item['price'] * item['qty']) as int);

  Future<void> handleSimpanTransaksi() async {
    setState(() => isLoading = true);
    final menus = await menuService.getMenus();
    validateCartStock(menus);
    try {
      await orderService.createOrder(widget.userId, total, cart);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Transaksi Berhasil!"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        cart.clear();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar(e.toString().replaceAll('Exception:', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildMainContent(),
                  ),
                ),
                _buildCartSidebar(),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildMainContent(),
                  ),
                ),
                _buildMobileCartSummary(),
              ],
            ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 15),
        _buildCategoryFilter(),
        const SizedBox(height: 20),
        Expanded(child: _buildMenuGrid()),
      ],
    );
  }

  Widget _buildMobileCartSummary() {
    if (cart.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${cart.length} Item",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "Rp $total",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFAF7705),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: _buildCartSidebar(),
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D4C41),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Lihat Pesanan",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Cari menu favorit...",
          hintStyle: GoogleFonts.poppins(fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFAF7705)),
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFAF7705)),
          ),
        ),
        onChanged: (val) {
          setState(() {
            searchQuery = val.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<List<CategoryModel>>(
      stream: categoryStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final categories = snapshot.data!;

        if (selectedCategoryId != "all" &&
            !categories.any((c) => c.id == selectedCategoryId)) {
          selectedCategoryId = "all";
        }

        return SizedBox(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _categoryChipSemua(),
              ...categories.map((c) => _categoryChip(c)),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryChipSemua() {
    bool isSelected = selectedCategoryId == "all";

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: const Text("Semua"),
        selected: isSelected,
        onSelected: (_) => setState(() => selectedCategoryId = "all"),
        selectedColor: const Color(0xFFAF7705),
      ),
    );
  }

  Widget _categoryChip(CategoryModel c) {
    bool isSelected = selectedCategoryId == c.id;
    bool isDisabled = !c.isActive;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.name,
              style: GoogleFonts.poppins(
                color: isDisabled
                    ? Colors.grey
                    : (isSelected ? Colors.white : Colors.black),
              ),
            ),
            if (!c.isActive) ...[
              const SizedBox(width: 5),
              Text(
                "(Nonaktif)",
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.red),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: isDisabled
            ? null
            : (_) => setState(() => selectedCategoryId = c.id),
        selectedColor: const Color(0xFFAF7705),
        backgroundColor: isDisabled ? Colors.grey.shade200 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return StreamBuilder<List<MenuModel>>(
      stream: menuStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (snapshot.connectionState == ConnectionState.active &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: GridView.builder(
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          );
        }

        List<MenuModel> menus = [];

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          menus = snapshot.data!;
        } else if (initialMenus.isNotEmpty) {
          menus = initialMenus;
        }

        if (!isLoaded && menus.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (menus.isEmpty) {
          return const Center(child: Text("Belum ada menu"));
        }

        if (selectedCategoryId != "all" &&
            !menus.any((m) => m.categoryId == selectedCategoryId)) {
          selectedCategoryId = "all";
        }

        final filteredMenus = menus.where((m) {
          final matchSearch = m.name.toLowerCase().contains(searchQuery);
          final matchCategory =
              selectedCategoryId == "all" || m.categoryId == selectedCategoryId;
          return matchSearch && matchCategory;
        }).toList();

        if (filteredMenus.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 15),
                Text(
                  searchQuery.isNotEmpty
                      ? "Menu tidak ditemukan"
                      : "Tidak ada menu di kategori ini",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  searchQuery.isNotEmpty
                      ? "Coba kata kunci lain"
                      : "Coba pilih kategori lain atau reset filter",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = "";
                      selectedCategoryId = "all";
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    searchQuery.isNotEmpty ? "Reset Pencarian" : "Reset Filter",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAF7705),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredMenus.length,
          itemBuilder: (context, index) {
            final m = filteredMenus[index];

            return Opacity(
              opacity: m.status ? 1 : 0.5,
              child: Stack(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final recipe = await menuService.getRecipeForMenu(m.id);

                        if (recipe.isEmpty) {
                          _showErrorSnackBar("Menu belum siap dijual");
                          return;
                        }

                        if (!m.status) {
                          _showErrorSnackBar("Menu sedang tidak tersedia");
                          return;
                        }

                        showMenuDetail(m);
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                                image:
                                    m.imageUrl != null && m.imageUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(m.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey[200],
                              ),
                              child: (m.imageUrl == null || m.imageUrl!.isEmpty)
                                  ? const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                ),
                                Text(
                                  "Rp ${m.price}",
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFFAF7705),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                FutureBuilder(
                                  future: menuService.getRecipeForMenu(m.id),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox();
                                    }

                                    final recipeKosong =
                                        (snapshot.data as List).isEmpty;

                                    if (recipeKosong) {
                                      return Text(
                                        "Belum bisa dijual",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.orange,
                                        ),
                                      );
                                    }

                                    if (!m.status) {
                                      return Text(
                                        "Tidak tersedia",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.red,
                                        ),
                                      );
                                    }

                                    return const SizedBox();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!m.status)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Nonaktif",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartSidebar() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Container(
      width: isDesktop ? 350 : double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFFAF7705),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Pesanan",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (cart.isNotEmpty)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Kosongkan Pesanan?"),
                        content: Text("Semua item akan dihapus."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              clearCart();
                            },
                            child: const Text("Hapus Semua"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  tooltip: "Clear Cart",
                ),
            ],
          ),
          const Divider(height: 30),
          Expanded(
            child: cart.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fastfood_outlined,
                        size: 50,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Keranjang masih kosong",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];

                      return Dismissible(
                        key: Key(item['id'] + index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() {
                            cart.removeAt(index);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${item['name']} dihapus"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: _buildCartItem(index),
                      );
                    },
                  ),
          ),
          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Bayar", style: GoogleFonts.poppins(fontSize: 16)),
                Text(
                  "Rp $total",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFAF7705),
                  ),
                ),
              ],
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = cart[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp ${item['price']}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (!isStockSufficientSync(item['selected_recipe'])) ...[
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  Text(
                    "Stok tidak cukup",
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => decreaseQty(index),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
              ),
              Text(
                "${item['qty']}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => increaseQty(index),
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Color(0xFFAF7705),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: (cart.isEmpty || isLoading) ? null : handleSimpanTransaksi,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6D4C41),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "SIMPAN TRANSAKSI",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
