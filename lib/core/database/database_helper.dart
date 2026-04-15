import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('amar_wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createExpensesTable(db);
    await _createIncomeTable(db);
    await _createLedgerTable(db);
    await _createBudgetsTable(db);
    await _createGoalsTable(db);
    await _createTagsTable(db);
    await _createExpenseTagsTable(db);
    await _createSubscriptionsTable(db);
    await _createWalletsTable(db);
    // Add walletId column in fresh installs
    // (already part of expenses CREATE for v3 fresh installs)
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: add financial tables
      await _createIncomeTable(db);
      await _createLedgerTable(db);
      await _createBudgetsTable(db);
      await _createGoalsTable(db);
    }
    if (oldVersion < 3) {
      // v2 → v3: add tags, subscriptions, wallets, expense walletId
      await _createTagsTable(db);
      await _createExpenseTagsTable(db);
      await _createSubscriptionsTable(db);
      await _createWalletsTable(db);
      // Add walletId column to existing expenses table
      try {
        await db.execute(
            'ALTER TABLE expenses ADD COLUMN walletId TEXT DEFAULT "default"');
      } catch (_) {
        // Column may already exist
      }
    }
  }

  Future _createExpensesTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS expenses (
  id TEXT PRIMARY KEY,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  date TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  walletId TEXT DEFAULT "default"
)
''');
  }

  Future _createIncomeTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS income (
  id TEXT PRIMARY KEY,
  amount REAL NOT NULL,
  source TEXT NOT NULL,
  description TEXT NOT NULL,
  date TEXT NOT NULL
)
''');
  }

  Future _createLedgerTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ledger (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  person TEXT NOT NULL,
  amount REAL NOT NULL,
  note TEXT DEFAULT "",
  date TEXT NOT NULL,
  isPaid INTEGER DEFAULT 0
)
''');
  }

  Future _createBudgetsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS budgets (
  category TEXT PRIMARY KEY,
  monthlyLimit REAL NOT NULL
)
''');
  }

  Future _createGoalsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  targetAmount REAL NOT NULL,
  savedAmount REAL NOT NULL DEFAULT 0,
  deadline TEXT,
  emoji TEXT DEFAULT "🎯",
  createdAt TEXT NOT NULL
)
''');
  }

  Future _createTagsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS tags (
  name TEXT PRIMARY KEY,
  colorHex TEXT DEFAULT "#00897B"
)
''');
  }

  Future _createExpenseTagsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS expense_tags (
  expenseId TEXT NOT NULL,
  tagName TEXT NOT NULL,
  PRIMARY KEY (expenseId, tagName)
)
''');
  }

  Future _createSubscriptionsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  frequency TEXT NOT NULL,
  category TEXT DEFAULT "Utilities",
  startDate TEXT NOT NULL,
  nextDueDate TEXT,
  isActive INTEGER DEFAULT 1,
  icon TEXT DEFAULT "🔄"
)
''');
  }

  Future _createWalletsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS wallets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT DEFAULT "💰",
  colorHex TEXT DEFAULT "#004D43",
  createdAt TEXT NOT NULL
)
''');
    // Insert default wallet
    await db.execute('''
INSERT OR IGNORE INTO wallets (id, name, emoji, colorHex, createdAt) 
VALUES ("default", "Personal", "💼", "#004D43", "${DateTime.now().toIso8601String()}")
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
