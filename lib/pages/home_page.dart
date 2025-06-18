import 'package:catatsaku_full/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:catatsaku_full/models/database.dart';
import 'package:catatsaku_full/models/transaction_with_category.dart';
import 'package:catatsaku_full/pages/transaction_page.dart';
import 'package:catatsaku_full/pages/welcome_screen.dart';

class HomePage extends StatefulWidget {
  final DateTime selectedDate;

  const HomePage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDb database = AppDb();

  // Fungsi untuk handle back press dengan konfirmasi
  Future<bool> _onWillPop() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home", style: GoogleFonts.montserrat()),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: SafeArea(
          child: StreamBuilder<List<TransactionWithCategory>>(
            stream: database.getTransactionByDateRepo(widget.selectedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                final transactions = snapshot.data!;
                final totalIncome = transactions
                    .where((tx) => tx.category.type == 1)
                    .fold<int>(0, (sum, tx) => sum + tx.transaction.amount);
                final totalExpense = transactions
                    .where((tx) => tx.category.type == 2)
                    .fold<int>(0, (sum, tx) => sum + tx.transaction.amount);
                final balance = totalIncome - totalExpense;

                return ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    _buildSummaryRow(totalIncome, totalExpense, balance),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text("Transactions",
                          style: GoogleFonts.montserrat(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    if (transactions.isNotEmpty)
                      ...transactions.map((tx) => _buildTransactionTile(tx)).toList()
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text("Belum ada transaksi",
                              style: GoogleFonts.montserrat(fontSize: 14)),
                        ),
                      ),
                  ],
                );
              } else {
                return const Center(child: Text("Gagal memuat data"));
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (_) =>
                      const TransactionPage(transactionsWithCategory: null),
                ))
                .then((_) {
              setState(() {}); // Refresh UI
            });
          },
          backgroundColor: Colors.indigo,
          child: Text(
            "+",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // Widget Ringkasan Saldo
  Widget _buildSummaryRow(int income, int expense, int balance) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryCard(
            icon: Icons.arrow_downward,
            label: "Income",
            amount: income,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            icon: Icons.arrow_upward,
            label: "Expense",
            amount: expense,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            icon: Icons.account_balance_wallet,
            label: "Balance",
            amount: balance,
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required int amount,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.montserrat(fontSize: 12, color: color)),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format(amount),
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Daftar Transaksi
  Widget _buildTransactionTile(TransactionWithCategory tx) {
    final isIncome = tx.category.type == 1;
    final amountColor = isIncome ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: amountColor,
            ),
          ),
          title: Text(
            tx.category.name,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            tx.transaction.description,
            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (isIncome ? '+' : '-') +
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(tx.transaction.amount),
                style: GoogleFonts.montserrat(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    onPressed: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (_) => TransactionPage(transactionsWithCategory: tx),
                          ))
                          .then((_) {
                        setState(() {});
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () async {
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: const Text('Hapus transaksi ini?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Hapus')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await database.deleteTransactionById(tx.transaction.id);
                        setState(() {}); // Refresh setelah hapus
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
