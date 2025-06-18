import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:catatsaku_full/models/database.dart';
import 'package:catatsaku_full/models/transaction.dart';
import 'package:catatsaku_full/models/transaction_with_category.dart';
import 'package:drift/drift.dart' hide Column;

class TransactionPage extends StatefulWidget {
  final TransactionWithCategory? transactionsWithCategory;

  const TransactionPage({Key? key, required this.transactionsWithCategory})
      : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final AppDb database = AppDb();

  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();

  bool isExpense = true;
  int type = 2;
  Category? selectedCategory;

  List<bool> isSelected = [false, true]; // [Pemasukan, Pengeluaran]

  bool get isEditMode => widget.transactionsWithCategory != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final transaction = widget.transactionsWithCategory!;
      amountController.text = transaction.transaction.amount.toString();
      descriptionController.text = transaction.transaction.description;
      dateController.text = DateFormat('yyyy-MM-dd')
          .format(transaction.transaction.transaction_date);
      type = transaction.category.type;
      selectedCategory = transaction.category;
      isExpense = type == 2;
      isSelected = [type == 1, type == 2];
    } else {
      dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  Future<List<Category>> getAllCategory(int type) {
    return database.getAllCategoryRepo(type);
  }

  Future<void> insertTransaction(String description, int categoryId,
      int amount, DateTime date) async {
    final now = DateTime.now();
    await database.into(database.transactions).insertReturning(
      TransactionsCompanion.insert(
        description: description,
        category_id: categoryId,
        amount: amount,
        transaction_date: date,
        created_at: now,
        updated_at: now,
      ),
    );
  }

  Future<void> updateTransaction(int id, String description, int categoryId,
      int amount, DateTime date) async {
    final now = DateTime.now();
    await (database.update(database.transactions)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      TransactionsCompanion(
        description: Value(description),
        category_id: Value(categoryId),
        amount: Value(amount),
        transaction_date: Value(date),
        updated_at: Value(now),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = isExpense ? Colors.red : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? "Edit Transaction" : "Add Transaction",
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpense
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: buttonColor,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExpense ? "Expense" : "Income",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: buttonColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ToggleButtons(
                    isSelected: isSelected,
                    onPressed: (int index) {
                      setState(() {
                        for (int i = 0; i < isSelected.length; i++) {
                          isSelected[i] = i == index;
                        }
                        isExpense = index == 1;
                        type = isExpense ? 2 : 1;
                        selectedCategory = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: buttonColor,
                    color: Colors.grey[700],
                    constraints:
                        const BoxConstraints(minHeight: 40, minWidth: 120),
                    children: [
                      Text("Income", style: GoogleFonts.montserrat()),
                      Text("Expense", style: GoogleFonts.montserrat()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildAmountInput(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildDateInput(),
            const SizedBox(height: 16),
            _buildDescriptionInput(),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(
                  isEditMode ? 'Update' : 'Save',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Jumlah", style: GoogleFonts.montserrat()),
        TextFormField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Contoh: 10000',
            border: UnderlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Text(
          formatRupiah(amountController.text),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Kategori", style: GoogleFonts.montserrat()),
        const SizedBox(height: 8),
        FutureBuilder<List<Category>>(
          future: getAllCategory(type),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final categories = snapshot.data!;
              selectedCategory ??= categories.first;

              return DropdownButton<Category>(
                isExpanded: true,
                value: selectedCategory,
                icon: const Icon(Icons.arrow_drop_down),
                elevation: 2,
                underline: Container(height: 1, color: Colors.grey),
                onChanged: (newValue) {
                  setState(() => selectedCategory = newValue);
                },
                items: categories.map((cat) {
                  return DropdownMenuItem<Category>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
              );
            } else {
              return const Text("Belum ada kategori.");
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tanggal", style: GoogleFonts.montserrat()),
        TextFormField(
          controller: dateController,
          decoration: const InputDecoration(
            hintText: "Pilih tanggal",
            border: UnderlineInputBorder(),
          ),
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              setState(() {
                dateController.text =
                    DateFormat('yyyy-MM-dd').format(picked);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Deskripsi", style: GoogleFonts.montserrat()),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            hintText: 'Contoh: Makan siang, Bayar listrik...',
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (selectedCategory == null ||
        amountController.text.isEmpty ||
        dateController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua data")),
      );
      return;
    }

    final description = descriptionController.text;
    final categoryId = selectedCategory!.id;
    final amount = int.tryParse(amountController.text) ?? 0;
    final date = DateTime.parse(dateController.text);

    if (isEditMode) {
      await updateTransaction(
        widget.transactionsWithCategory!.transaction.id,
        description,
        categoryId,
        amount,
        date,
      );
    } else {
      await insertTransaction(description, categoryId, amount, date);
    }

    Navigator.pop(context, true);
  }
}

String formatRupiah(String numberString) {
  if (numberString.isEmpty) return 'Rp 0';
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final parsed = int.tryParse(numberString.replaceAll('.', '')) ?? 0;
  return formatter.format(parsed);
}
