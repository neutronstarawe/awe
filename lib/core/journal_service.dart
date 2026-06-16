import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/journal_entry.dart';

class JournalService {
  static final JournalService _instance = JournalService._();
  factory JournalService() => _instance;
  JournalService._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'journal.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE entries('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'body TEXT NOT NULL,'
        'created_at TEXT NOT NULL'
        ')',
      ),
    );
  }

  Future<List<JournalEntry>> all() async {
    final db = await _database;
    final rows = await db.query('entries', orderBy: 'created_at DESC');
    return rows.map(JournalEntry.fromMap).toList();
  }

  Future<JournalEntry> insert(String body) async {
    final db = await _database;
    final entry = JournalEntry(body: body, createdAt: DateTime.now());
    final id = await db.insert('entries', entry.toMap());
    return JournalEntry(id: id, body: body, createdAt: entry.createdAt);
  }

  Future<void> update(JournalEntry entry) async {
    final db = await _database;
    await db.update('entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
}
