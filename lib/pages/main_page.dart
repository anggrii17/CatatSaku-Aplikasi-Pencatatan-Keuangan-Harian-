import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:catatsaku_full/models/database.dart';
import 'package:catatsaku_full/pages/category_page.dart';
import 'package:catatsaku_full/pages/home_page.dart';
import 'package:catatsaku_full/pages/transaction_page.dart';
import 'package:catatsaku_full/screens/account_screen.dart';

class MainPage extends StatefulWidget {
  final AppDb db;
  const MainPage({Key? key, required this.db}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late DateTime selectedDate;
  int currentIndex = 0;

  @override
  void initState() {
    selectedDate = DateTime.now();
    super.initState();
  }

  void updateView(int index, DateTime? date) {
    setState(() {
      if (date != null) {
        selectedDate = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      }
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(selectedDate: selectedDate),
      const CategoryPage(),
      AccountScreen(db: widget.db),
    ];

    return Scaffold(
      appBar: currentIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(250),
              child: CalendarAppBar(
                fullCalendar: true,
                backButton: false,
                accent: Colors.indigo,
                locale: 'id',
                onDateChanged: (value) {
                  updateView(0, value);
                },
                lastDate: DateTime.now(),
              ),
            )
          : AppBar(
              backgroundColor: Colors.indigo,
              leading: currentIndex != 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => updateView(0, DateTime.now()),
                    )
                  : null,
              title: Text(
                currentIndex == 1 ? "Kategori" : "Akun",
                style: GoogleFonts.montserrat(),
              ),
              centerTitle: true,
            ),
      body: _pages[currentIndex],
      // FAB dihapus sesuai permintaan
      // floatingActionButton: ...
      // floatingActionButtonLocation: ...
      bottomNavigationBar: BottomAppBar(
        // Tidak perlu shape CircularNotchedRectangle karena FAB tidak digunakan
        color: Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.home,
                    color: currentIndex == 0 ? Colors.indigo : Colors.grey),
                onPressed: () => updateView(0, DateTime.now()),
              ),
              IconButton(
                icon: Icon(Icons.list,
                    color: currentIndex == 1 ? Colors.indigo : Colors.grey),
                onPressed: () => updateView(1, null),
              ),
              IconButton(
                icon: Icon(Icons.account_circle,
                    color: currentIndex == 2 ? Colors.indigo : Colors.grey),
                onPressed: () => updateView(2, null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
