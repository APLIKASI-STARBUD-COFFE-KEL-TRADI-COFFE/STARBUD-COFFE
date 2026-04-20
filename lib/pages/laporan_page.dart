import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final accentColor = const Color(0xFFAF7705);
  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  DateTimeRange? _selectedDateRange;

  List<Map<String, dynamic>> _currentTransactions = [];
  int _totalIncome = 0;
  int _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  Future<List<Map<String, dynamic>>> _getAllTransactions() async {
    final startIso = _selectedDateRange!.start.toIso8601String();
    final endIso = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
      23,
      59,
      59,
    ).toIso8601String();

    final responses = await Future.wait([
      Supabase.instance.client
          .from('orders')
          .select('*')
          .gte('created_at', startIso)
          .lte('created_at', endIso),
      Supabase.instance.client
          .from('expenses')
          .select('*')
          .gte('created_at', startIso)
          .lte('created_at', endIso),
    ]);

    final incomeResponse = responses[0] as List;
    final expenseResponse = responses[1] as List;

    List<Map<String, dynamic>> combinedList = [];
    int tempIncome = 0;
    int tempExpense = 0;

    for (var item in incomeResponse) {
      final amount = (item['total'] ?? 0) as int;
      tempIncome += amount;
      combinedList.add({
        'type': 'income',
        'id': item['id'],
        'display_title':
            "ORD #${item['id'].toString().length > 5 ? item['id'].toString().substring(0, 5) : item['id']}",
        'amount': amount,
        'created_at': item['created_at'],
      });
    }

    for (var item in expenseResponse) {
      final amount = (item['amount'] ?? 0) as int;
      tempExpense += amount;
      combinedList.add({
        'type': 'expense',
        'id': item['id'],
        'display_title': item['name'] ?? "Pengeluaran Tanpa Nama",
        'amount': amount,
        'created_at': item['created_at'],
      });
    }

    combinedList.sort(
      (a, b) => DateTime.parse(
        b['created_at'],
      ).compareTo(DateTime.parse(a['created_at'])),
    );
    _currentTransactions = combinedList;
    _totalIncome = tempIncome;
    _totalExpense = tempExpense;

    return combinedList;
  }

  Future<int> _getTotalIncome() async => _totalIncome;
  Future<int> _getTotalExpense() async => _totalExpense;
  Future<int> _getProfit() async => _totalIncome - _totalExpense;

  Future<void> _addExpense(String name, int amount) async {
    await Supabase.instance.client.from('expenses').insert({
      'name': name,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    });
    setState(() {});
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: accentColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
    }
  }

  void _showAddExpenseDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            "Tambah Pengeluaran",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Pengeluaran",
                ),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "Jumlah Nominal"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = int.tryParse(amountController.text) ?? 0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nama pengeluaran wajib diisi"),
                    ),
                  );
                  return;
                }

                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jumlah harus lebih dari 0")),
                  );
                  return;
                }

                if (amount > 10000000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Maksimal pengeluaran 10.000.000"),
                    ),
                  );
                  return;
                }
                await _addExpense(name, amount);
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: _pickDateRange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                "${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, Future<int> future, Color color) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(
                  currencyFormatter.format(snapshot.data ?? 0),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllTransactions(),
        builder: (context, snapshot) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Laporan Keuangan",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Data transaksi masuk & keluar",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAddExpenseDialog(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accentColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Tambah Pengeluaran",
                                  style: GoogleFonts.poppins(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _showDownloadMenu(context),
                          icon: const Icon(Icons.file_download_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor: accentColor.withOpacity(0.1),
                            foregroundColor: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildDateFilter(),
              _buildSummaryCard(
                "Total Pemasukan",
                _getTotalIncome(),
                accentColor,
              ),
              _buildSummaryCard(
                "Total Pengeluaran",
                _getTotalExpense(),
                Colors.red,
              ),
              _buildSummaryCard("Laba Bersih", _getProfit(), Colors.green),
              const SizedBox(height: 10),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return const Center(
                        child: Text("Belum ada data transaksi"),
                      );

                    final transactions = snapshot.data!;
                    Map<String, List<Map<String, dynamic>>> groupedData = {};

                    for (var tx in transactions) {
                      String monthYear = DateFormat(
                        'MMMM yyyy',
                      ).format(DateTime.parse(tx['created_at']));
                      if (groupedData[monthYear] == null)
                        groupedData[monthYear] = [];
                      groupedData[monthYear]!.add(tx);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: groupedData.keys.length,
                      itemBuilder: (context, sectionIndex) {
                        String monthYear = groupedData.keys.elementAt(
                          sectionIndex,
                        );
                        List<Map<String, dynamic>> items =
                            groupedData[monthYear]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              child: Text(
                                monthYear,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            ...items.map((item) {
                              final date = DateTime.parse(
                                item['created_at'],
                              ).toLocal();
                              final bool isExpense = item['type'] == 'expense';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          (isExpense
                                                  ? Colors.red
                                                  : Colors.green)
                                              .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isExpense
                                          ? Icons.arrow_outward
                                          : Icons.arrow_downward,
                                      color: isExpense
                                          ? Colors.red
                                          : Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    item['display_title'],
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormat('dd MMM • HH:mm').format(date),
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    "${isExpense ? '-' : '+'} ${currencyFormatter.format(item['amount'])}",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: isExpense
                                          ? Colors.red
                                          : Colors.green,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDownloadMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Export Laporan",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            _buildDownloadOption(
              Icons.picture_as_pdf,
              "Export sebagai PDF",
              Colors.red,
              onTap: () => _exportPDF(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      onTap: onTap,
    );
  }

  Future<void> _exportPDF() async {
    final data = _currentTransactions;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "LAPORAN KEUANGAN STARBUD COFFEE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Periode: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown),
            cellAlignment: pw.Alignment.centerLeft,
            context: context,
            data: <List<String>>[
              <String>['Tanggal', 'Keterangan', 'Tipe', 'Nominal'],
              ...data.map(
                (item) => [
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(DateTime.parse(item['created_at'])),
                  item['display_title'],
                  item['type'] == 'income' ? 'Pemasukan' : 'Pengeluaran',
                  currencyFormatter.format(item['amount']),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Total Pemasukan: ${currencyFormatter.format(_totalIncome)}",
              ),
              pw.Text(
                "Total Pengeluaran: ${currencyFormatter.format(_totalExpense)}",
              ),
              pw.Text(
                "Laba Bersih: ${currencyFormatter.format(_totalIncome - _totalExpense)}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
