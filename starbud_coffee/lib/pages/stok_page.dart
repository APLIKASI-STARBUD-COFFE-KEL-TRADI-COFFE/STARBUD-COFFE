import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:starbud_coffe/services/stock_service.dart';
import 'package:starbud_coffe/models/stock_model.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final service = StockService();
  List<StockModel> allStocks = [];
  List<StockModel> filteredStocks = [];
  bool isLoading = true;
  final searchController = TextEditingController();

  String selectedFilter = "Semua";

  final accentColor = const Color(0xFFAF7705);
  final dangerColor = const Color(0xFFE53935);
  final warningColor = const Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await service.getStocks();

      data.sort((a, b) {
        double ratioA = a.quantity / (a.minStock == 0 ? 1 : a.minStock);
        double ratioB = b.quantity / (b.minStock == 0 ? 1 : b.minStock);
        return ratioA.compareTo(ratioB);
      });

      setState(() {
        allStocks = data;
        filteredStocks = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _runFilter(String enteredKeyword) {
    _applyFilter();
  }

  void _applyFilter() {
    List<StockModel> result = allStocks;

    if (selectedFilter == "Habis") {
      result = result.where((s) => s.quantity <= 0).toList();
    } else if (selectedFilter == "Menipis") {
      result = result
          .where((s) => s.quantity > 0 && s.quantity <= s.minStock)
          .toList();
    } else if (selectedFilter == "Aman") {
      result = result.where((s) => s.quantity > s.minStock).toList();
    }

    if (searchController.text.trim().isNotEmpty) {
      final keyword = searchController.text.toLowerCase().trim();

      result = result.where((s) {
        return s.name.toLowerCase().contains(keyword);
      }).toList();
    }

    setState(() => filteredStocks = result);
  }

  void showEditDialog(StockModel stock) {
    final quantityController = TextEditingController(
      text: stock.quantity.toString(),
    );
    final minStockController = TextEditingController(
      text: stock.minStock.toString(),
    );

    final initialQty = stock.quantity;
    final initialMin = stock.minStock;

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitted = false;
        String? selectedUnit = stock.unit;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                "Update Stok: ${stock.name}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Jumlah Stok Sekarang",
                      errorText: isSubmitted
                          ? quantityController.text.isEmpty
                                ? "Wajib diisi"
                                : int.tryParse(quantityController.text) == null
                                ? "Harus angka"
                                : int.parse(quantityController.text) < 0
                                ? "Tidak boleh negatif"
                                : null
                          : null,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: minStockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Batas Minimal Stok",
                      errorText: isSubmitted
                          ? minStockController.text.isEmpty
                                ? "Wajib diisi"
                                : int.tryParse(minStockController.text) == null
                                ? "Harus angka"
                                : int.parse(minStockController.text) < 0
                                ? "Tidak boleh negatif"
                                : null
                          : null,
                    ),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    hint: const Text("Pilih satuan"),
                    decoration: InputDecoration(
                      labelText: "Satuan",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: isSubmitted && selectedUnit == null
                          ? "Wajib diisi"
                          : null,
                    ),
                    items: ["pcs", "gram", "ml", "liter", "kg", "botol", "pack"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedUnit = val;
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    if (quantityController.text == stock.quantity.toString() &&
                        minStockController.text == stock.minStock.toString()) {
                      Navigator.pop(context);
                    } else {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Konfirmasi"),
                          content: const Text(
                            "Perubahan belum disimpan, keluar?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("Tidak"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                Navigator.pop(context);
                              },
                              child: const Text("Ya"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Batal",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                  onPressed: () async {
                    setStateDialog(() => isSubmitted = true);

                    if (quantityController.text.isEmpty ||
                        minStockController.text.isEmpty ||
                        selectedUnit == null ||
                        int.tryParse(quantityController.text) == null ||
                        int.tryParse(minStockController.text) == null ||
                        int.parse(quantityController.text) < 0 ||
                        int.parse(minStockController.text) < 0) {
                      return;
                    }

                    if (int.parse(quantityController.text) > 100000 ||
                        int.parse(minStockController.text) > 100000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Nilai stok terlalu besar"),
                        ),
                      );
                      return;
                    }

                    final newQty = int.parse(quantityController.text);
                    final newMin = int.parse(minStockController.text);

                    if (newQty == initialQty &&
                        newMin == initialMin &&
                        selectedUnit == stock.unit) {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Info"),
                          content: const Text("Tidak ada perubahan data"),
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

                    final updatedData = StockModel(
                      id: stock.id,
                      name: stock.name,
                      quantity: newQty,
                      minStock: newMin,
                      unit: selectedUnit!,
                    );

                    try {
                      await service.updateStock(updatedData);

                      if (!mounted) return;

                      Navigator.pop(context);
                      load();

                      Future.delayed(const Duration(milliseconds: 100), () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text("Berhasil"),
                            content: const Text("Stok berhasil diperbarui 🎉"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal update: $e")),
                      );
                    }
                  },
                  child: Text(
                    "Simpan",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showAddStockDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final minController = TextEditingController();

    String? selectedUnit;
    bool isSubmitted = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                "Tambah Stok",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Nama Barang",
                      errorText: isSubmitted && nameController.text.isEmpty
                          ? "Wajib diisi"
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Jumlah Stok",
                      errorText: isSubmitted
                          ? qtyController.text.isEmpty
                                ? "Wajib diisi"
                                : int.tryParse(qtyController.text) == null
                                ? "Harus angka"
                                : int.parse(qtyController.text) < 0
                                ? "Tidak boleh negatif"
                                : null
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Minimal Stok",
                      errorText: isSubmitted
                          ? minController.text.isEmpty
                                ? "Wajib diisi"
                                : int.tryParse(minController.text) == null
                                ? "Harus angka"
                                : int.parse(minController.text) < 0
                                ? "Tidak boleh negatif"
                                : null
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    hint: const Text("Pilih satuan"),
                    decoration: InputDecoration(
                      labelText: "Satuan",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: isSubmitted && selectedUnit == null
                          ? "Wajib diisi"
                          : null,
                    ),
                    items: ["pcs", "gram", "ml", "liter", "kg", "botol", "pack"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedUnit = val;
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty &&
                        qtyController.text.isEmpty &&
                        minController.text.isEmpty &&
                        selectedUnit == null) {
                      Navigator.pop(context);
                    } else {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Konfirmasi"),
                          content: const Text("Data belum disimpan, keluar?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("Tidak"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                Navigator.pop(context);
                              },
                              child: const Text("Ya"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Batal",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    setStateDialog(() => isSubmitted = true);

                    if (selectedUnit == null) return;

                    final name = nameController.text.trim();

                    final isExist = allStocks.any(
                      (s) => s.name.toLowerCase().trim() == name.toLowerCase(),
                    );

                    if (isExist) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Nama stok sudah ada")),
                      );
                      return;
                    }

                    if (name.isEmpty ||
                        qtyController.text.isEmpty ||
                        minController.text.isEmpty ||
                        selectedUnit == null ||
                        int.tryParse(qtyController.text) == null ||
                        int.tryParse(minController.text) == null ||
                        int.parse(qtyController.text) < 0 ||
                        int.parse(minController.text) < 0) {
                      return;
                    }

                    final qty = int.parse(qtyController.text);
                    final min = int.parse(minController.text);

                    if (int.parse(qtyController.text) > 100000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Jumlah stok terlalu besar"),
                        ),
                      );
                      return;
                    }

                    if (int.parse(minController.text) > 100000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Minimal stok terlalu besar"),
                        ),
                      );
                      return;
                    }

                    final newStock = StockModel(
                      id: "",
                      name: name,
                      quantity: qty,
                      minStock: min,
                      unit: selectedUnit!,
                    );

                    try {
                      await service.addStock(newStock);

                      if (!mounted) return;

                      Navigator.pop(context);
                      load();

                      Future.delayed(const Duration(milliseconds: 100), () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text("Sukses"),
                            content: const Text("Data berhasil disimpan 🎉"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                    }
                  },
                  child: Text(
                    "Simpan",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final emptyItems = allStocks.where((s) => s.quantity <= 0).toList();
    final lowStockItems = allStocks
        .where((s) => s.quantity > 0 && s.quantity <= s.minStock)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,

      body: RefreshIndicator(
        onRefresh: load,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: _runFilter,
                      decoration: InputDecoration(
                        hintText: "Cari stok barang...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  searchController.clear();
                                  _runFilter("");
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  ElevatedButton.icon(
                    onPressed: () {
                      showAddStockDialog();
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      "Tambah Stok",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip("Semua"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Habis"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Menipis"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Aman"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _buildBoldHighlightCard(
                      "Habis",
                      emptyItems,
                      dangerColor,
                      Icons.cancel_presentation_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildBoldHighlightCard(
                      "Menipis",
                      lowStockItems,
                      warningColor,
                      Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Daftar Stok Barang",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),

            Expanded(
              child: filteredStocks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredStocks.length,
                      itemBuilder: (context, index) =>
                          _buildStockTile(filteredStocks[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoldHighlightCard(
    String title,
    List<StockModel> items,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              items.length.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (items.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Divider(color: Colors.white38, height: 1),
              ),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: items
                    .take(3)
                    .map(
                      (s) => Text(
                        "${s.name}${items.indexOf(s) < items.take(3).length - 1 ? ',' : ''}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "+${items.length - 3} lainnya",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockTile(StockModel s) {
    final isCritical = s.quantity <= s.minStock;
    final isEmpty = s.quantity <= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color:
                (isEmpty
                        ? dangerColor
                        : (isCritical ? warningColor : Colors.blue))
                    .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEmpty ? Icons.block : Icons.inventory_2_outlined,
            color: isEmpty
                ? dangerColor
                : (isCritical ? warningColor : Colors.blue),
            size: 20,
          ),
        ),
        title: Text(
          s.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (s.quantity / (s.minStock <= 0 ? 1 : s.minStock * 2))
                    .clamp(0.0, 1.0),
                backgroundColor: Colors.grey[100],
                color: isEmpty
                    ? dangerColor
                    : (isCritical ? warningColor : Colors.green),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Stok: ${s.quantity} ${s.unit} / Min: ${s.minStock} ${s.unit}",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.edit_square,
            color: Color(0xFFAF7705),
            size: 20,
          ),
          onPressed: () => showEditDialog(s),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = searchController.text.isNotEmpty;
    final isFiltering = selectedFilter != "Semua";

    String title = "Tidak ada stok ditemukan";
    String subtitle = "Coba ubah pencarian atau filter";

    if (isSearching && !isFiltering) {
      title = "Tidak ada hasil pencarian";
      subtitle = "Coba kata kunci lain";
    } else if (!isSearching && isFiltering) {
      title = "Tidak ada data di filter ini";
      subtitle = "Coba pilih filter lain";
    } else if (isSearching && isFiltering) {
      title = "Tidak ditemukan";
      subtitle = "Coba reset filter atau pencarian";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),

          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: () {
              searchController.clear();
              selectedFilter = "Semua";
              _applyFilter();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Reset", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : accentColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
