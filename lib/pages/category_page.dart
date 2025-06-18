import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catatsaku_full/models/category.dart';
import 'package:catatsaku_full/models/database.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool isExpense = true;
  late int type;
  final AppDb database = AppDb();
  final TextEditingController categoryNameController = TextEditingController();
  late Future<List<Category>> futureCategories;

  @override
  void initState() {
    super.initState();
    type = isExpense ? 2 : 1;
    futureCategories = getAllCategory(type);
  }

  Future<List<Category>> getAllCategory(int type) async {
    return await database.getAllCategoryRepo(type);
  }

  Future<void> insert(String name, int type) async {
    if (name.trim().isEmpty) return;
    DateTime now = DateTime.now();
    await database.into(database.categories).insertReturning(
      CategoriesCompanion.insert(
        name: name.trim(),
        type: type,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update(int categoryId, String newName) async {
    if (newName.trim().isEmpty) return;
    await database.updateCategoryRepo(categoryId, newName.trim());
  }

  void refreshData() {
    setState(() {
      futureCategories = getAllCategory(type);
    });
  }

  void openDialog(Category? category) {
    categoryNameController.text = category?.name ?? '';
    Color dialogColor = isExpense ? Colors.red : Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${category != null ? 'Edit' : 'Add'} ${isExpense ? "Expense" : "Income"} Category',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: dialogColor,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: categoryNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Category Name",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (category == null) {
                      await insert(categoryNameController.text, type);
                    } else {
                      await update(category.id, categoryNameController.text);
                    }
                    Navigator.of(context, rootNavigator: true).pop();
                    refreshData();
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void confirmDelete(int categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await database.deleteCategoryRepo(categoryId);
              Navigator.pop(context);
              refreshData();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color switchColor = isExpense ? Colors.red : Colors.blue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Judul tanpa tombol back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Manage Categories",
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              color: switchColor.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: isExpense,
                        inactiveTrackColor: Colors.blue[200],
                        inactiveThumbColor: Colors.blue,
                        activeColor: Colors.red,
                        onChanged: (bool value) {
                          setState(() {
                            isExpense = value;
                            type = isExpense ? 2 : 1;
                            futureCategories = getAllCategory(type);
                          });
                        },
                      ),
                      Text(
                        isExpense ? "Expense" : "Income",
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Category>>(
                future: futureCategories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final category = snapshot.data![index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: isExpense ? Colors.red[100] : Colors.blue[100],
                                child: Icon(
                                  isExpense ? Icons.upload : Icons.download,
                                  color: isExpense ? Colors.red : Colors.blue,
                                ),
                              ),
                              title: Text(
                                category.name,
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => openDialog(category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => confirmDelete(category.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Text("No categories yet", style: GoogleFonts.montserrat()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDialog(null),
        backgroundColor: switchColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
