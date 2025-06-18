import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:catatsaku_full/models/category.dart';
import 'package:catatsaku_full/models/transaction.dart';
import 'package:catatsaku_full/models/transaction_with_category.dart';

part 'database.g.dart';

// =============================
// ========== TABLES ==========
// =============================

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().customConstraint('UNIQUE')();
  TextColumn get password => text()();
}

// =============================
// ========== DATABASE =========
// =============================

@DriftDatabase(
  tables: [Categories, Transactions, Users],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  // =============================
  // ========== USERS ============
  // =============================

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<User?> getUserByEmailPassword(String email, String password) {
    return (select(users)
          ..where((u) => u.email.equals(email) & u.password.equals(password)))
        .getSingleOrNull();
  }

  Future<bool> checkEmailExists(String email) async {
    final result =
        await (select(users)..where((u) => u.email.equals(email))).get();
    return result.isNotEmpty;
  }

  Future<User?> getUserByEmail(String email) {
    return (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  Future<int> deleteUserByEmail(String email) {
    return (delete(users)..where((u) => u.email.equals(email))).go();
  }

  // =============================
  // ========= CATEGORY ==========
  // =============================

  Future<List<Category>> getAllCategoryRepo(int type) {
    return (select(categories)..where((tbl) => tbl.type.equals(type))).get();
  }

  Future<int> updateCategoryRepo(int id, String newName) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(name: Value(newName)),
    );
  }

  Future<int> deleteCategoryRepo(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  // =============================
  // ======= TRANSACTION =========
  // =============================

  Stream<List<TransactionWithCategory>> getTransactionByDateRepo(
      DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = (select(transactions)
          ..where((t) => t.transaction_date.isBetweenValues(start, end)))
        .join([
      innerJoin(categories, categories.id.equalsExp(transactions.category_id)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          row.readTable(transactions),
          row.readTable(categories),
        );
      }).toList();
    });
  }

  Future<int> insertTransaction(TransactionsCompanion data) {
    return into(transactions).insert(data);
  }

  Future<int> updateTransactionById(int id, TransactionsCompanion data) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(data);
  }

  Future<int> updateTransaction(TransactionsCompanion transaction) {
    return (update(transactions)
          ..where((t) => t.id.equals(transaction.id.value)))
        .write(transaction);
  }

  Future<int> deleteTransactionById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

// =============================
// ========== OPEN DB ==========
// =============================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
