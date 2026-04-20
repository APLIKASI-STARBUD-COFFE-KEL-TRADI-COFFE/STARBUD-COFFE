import 'package:flutter/material.dart';
import 'package:starbud_coffe/pages/category_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'transaksi_page.dart';
import 'transaksi_history_page.dart';
import 'menu_page.dart';
import 'stok_page.dart';
import 'user_page.dart';
import 'laporan_page.dart';
import 'package:starbud_coffe/models/user_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';

class DashboardPage extends StatefulWidget {
  final UserModel user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final primaryColor = const Color(0xFF6D4C41);
  final accentColor = const Color(0xFFAF7705);
  final bgColorLight = const Color(0xFFF8F9FA);

  String selectedFilter = "All Time";
  DateTime? customStart;
  DateTime? customEnd;

  Stream<List<Map<String, dynamic>>> getOrdersStream() => Supabase
      .instance
      .client
      .from('orders')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  Stream<List<Map<String, dynamic>>> getOrderItemsStream() =>
      Supabase.instance.client.from('order_items').stream(primaryKey: ['id']);

  Stream<List<Map<String, dynamic>>> getMenuStream() =>
      Supabase.instance.client.from('menu').stream(primaryKey: ['id']);

  Future<List<Map<String, dynamic>>> getTopItems() async {
    final data = await Supabase.instance.client.rpc('get_top_items');
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> filterOrders(List<Map<String, dynamic>> orders) {
    final now = DateTime.now();

    return orders.where((order) {
      final date = DateTime.parse(order['created_at']);

      if (selectedFilter == "Hari Ini") {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }

      if (selectedFilter == "Minggu Ini") {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(now.add(const Duration(seconds: 1)));
      }

      if (selectedFilter == "Custom") {
        if (customStart == null || customEnd == null) return true;
        return date.isAfter(
              customStart!.subtract(const Duration(seconds: 1)),
            ) &&
            date.isBefore(customEnd!.add(const Duration(days: 1)));
      }

      return true;
    }).toList();
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam lalu";
    if (diff.inDays < 7) return "${diff.inDays} hari lalu";

    return DateFormat('dd MMM yyyy').format(date);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Logout",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Yakin ingin keluar dari akun?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
                print("Logout error: $e");
              }

              if (!mounted) return;

              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF2D1B15),
                child: Text(
                  widget.user.username[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo,",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    widget.user.username,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=2070&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "StarBud Coffee",
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
            Text(
              "Premium Coffee & Healthy Life",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItems(List<Map<String, dynamic>> topItems) {
    final displayedItems = topItems.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 185,
          width: double.infinity,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 5),
            itemCount: displayedItems.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = displayedItems[index];
              List<Color> gradientColors;
              Color textColor = Colors.white;

              if (index == 0) {
                gradientColors = [const Color(0xFFFFD700), const Color(0xFFB8860B)];
              } else if (index == 1) {
                gradientColors = [const Color(0xFFD1984D), const Color(0xFF8B4513)];
              } else if (index == 2) {
                gradientColors = [const Color(0xFF5D4037), const Color(0xFF2D1B15)];
              } else {
                gradientColors = [const Color(0xFFF3EDE7), const Color(0xFFE6DED6)];
                textColor = Colors.brown[800]!;
              }

              return Container(
                width: 140, 
                margin: const EdgeInsets.only(right: 15, bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${index + 1}",
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['name'] ?? '-',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${item['total_qty'] ?? 0} Terjual",
                        style: GoogleFonts.poppins(
                          color: textColor.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _skeletonBox(height: 80)),
                const SizedBox(width: 12),
                Expanded(child: _skeletonBox(height: 80)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _skeletonBox(height: 80)),
                const SizedBox(width: 12),
                Expanded(child: _skeletonBox(height: 80)),
              ],
            ),
            const SizedBox(height: 20),
            _skeletonBox(width: 150, height: 20),
            const SizedBox(height: 12),
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _skeletonBox(height: 60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({double width = double.infinity, double height = 20}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _dashboardContent() {
    return StreamBuilder(
      stream: Rx.combineLatest3(
        getOrdersStream(),
        getMenuStream(),
        getOrderItemsStream(),
        (orders, menus, items) => {
          'orders': orders,
          'menus': menus,
          'items': items,
        },
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingSkeleton();
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final data = snapshot.data as Map<String, dynamic>;
        final allOrderItems = List<Map<String, dynamic>>.from(data['items']);
        final allOrders = List<Map<String, dynamic>>.from(data['orders']);
        final orders = filterOrders(allOrders);
        final filteredOrderIds = orders.map((e) => e['id']).toSet();

        final filteredItems = allOrderItems
            .where((item) => filteredOrderIds.contains(item['order_id']))
            .toList();
        final totalSold = filteredItems.fold<int>(
          0,
          (sum, i) => sum + (i['qty'] as int),
        );
        final menus = List<Map<String, dynamic>>.from(
          data['menus'],
        ).where((m) => m['status'] == true).toList();

        final menuMap = {for (var m in menus) m['id']: m['name']};

        Map<String, int> itemCount = {};

        for (var item in filteredItems) {
          final menuId = item['menu_id'];
          final qty = item['qty'] as int;

          final name = menuMap[menuId] ?? 'Unknown';

          itemCount[name] = (itemCount[name] ?? 0) + qty;
        }
        final topItems = itemCount.entries
            .map((e) => {'name': e.key, 'total_qty': e.value})
            .toList();

        topItems.sort(
          (a, b) => (b['total_qty'] as int).compareTo(a['total_qty'] as int),
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: HeaderClipper(),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/header_curve.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      _buildGreeting(),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: _buildHighlightBanner(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedFilter,
                        decoration: InputDecoration(
                          labelText: "Filter Waktu",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: ["Hari Ini", "Minggu Ini", "All Time", "Custom"]
                            .map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(e, style: GoogleFonts.poppins()),
                              );
                            })
                            .toList(),
                        onChanged: (val) async {
                          setState(() {
                            selectedFilter = val!;
                          });

                          if (val == "Custom") {
                            final pickedStart = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );

                            final pickedEnd = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );

                            setState(() {
                              customStart = pickedStart;
                              customEnd = pickedEnd;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: MediaQuery.of(context).size.width < 600
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _statCard("Transaksi", "${orders.length}", Icons.receipt_long_rounded, const Color(0xFF6366F1))),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard("Omset", NumberFormat.compactSimpleCurrency(locale: 'id', decimalDigits: 0).format(orders.fold(0, (s, i) => s + (i['total'] as num).toInt())), Icons.account_balance_wallet_rounded, const Color(0xFF10B981))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _statCard("Menu", "${menus.length}", Icons.restaurant_menu_rounded, const Color(0xFFF59E0B))),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard("Terjual", "$totalSold", Icons.analytics_rounded, const Color(0xFFEC4899))),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _statCard("Transaksi", "${orders.length}", Icons.receipt_long_rounded, const Color(0xFF6366F1))),
                          const SizedBox(width: 8),
                          Expanded(child: _statCard("Omset", NumberFormat.compactSimpleCurrency(locale: 'id', decimalDigits: 0).format(orders.fold(0, (s, i) => s + (i['total'] as num).toInt())), Icons.account_balance_wallet_rounded, const Color(0xFF10B981))),
                          const SizedBox(width: 8),
                          Expanded(child: _statCard("Menu", "${menus.length}", Icons.restaurant_menu_rounded, const Color(0xFFF59E0B))),
                          const SizedBox(width: 8),
                          Expanded(child: _statCard("Terjual", "$totalSold", Icons.analytics_rounded, const Color(0xFFEC4899))),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  "Menu Terlaris",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              topItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 70,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Belum ada data penjualan",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildTopItems(topItems),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Transaksi Terbaru",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransaksiHistoryPage(),
                        ),
                      ),
                      child: Text(
                        "Lihat Semua",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAF7705),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 70,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Belum ada transaksi",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orders.length > 3 ? 3 : orders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Container(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFAF7705).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt,
                                  color: Color(0xFFAF7705),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                "ORD #${order['id'].toString().substring(0, 5)}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM, HH:mm').format(
                                      DateTime.parse(order['created_at']),
                                    ),
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  Text(
                                    timeAgo(
                                      DateTime.parse(order['created_at']),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                "Rp ${order['total']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFAF7705),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _dashboardContent(),
      TransaksiPage(userId: widget.user.id),
      if (widget.user.role == "admin") ...[
        DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Material(
                color: Colors.white,
                child: TabBar(
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: "Menu"),
                    Tab(text: "Kategori"),
                    Tab(text: "Stok"),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [MenuPage(), CategoryPage(), StockPage()],
                ),
              ),
            ],
          ),
        ),
        const LaporanPage(),
        const UserPage(), 
      ],
    ];

    return Scaffold(
      backgroundColor: bgColorLight,
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF2D1B15), Color(0xFF5D4037), Color(0xFF2D1B15)],
            ),
          ),
        ),
        centerTitle: false,
        title: Text(
          "STARBUD COFFEE",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            offset: const Offset(-10, 45),
            color: Colors.grey[200]!.withOpacity(0.9),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onSelected: (value) {
              if (value == 'logout') _showLogoutDialog();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                height: 40,
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.black87, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Logout",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Beranda",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_rounded),
            label: "Transaksi",
          ),
          if (widget.user.role == "admin") ...[
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: "Produk",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: "Laporan",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: "User",
            ),
          ],
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 100);

    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 100,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}