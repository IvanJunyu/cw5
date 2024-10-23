import 'dart:ui';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'aquarium.db');
    return await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE fish(fish_id INTEGER PRIMARY KEY AUTOINCREMENT, speed REAL, color TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertFish(Fish fish) async {
    final db = await database;
    int id = await db.insert('fish', fish.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    fish.id = id;
  }

  Future<void> deleteFish(int id) async {
    final db = await database;
    await db.delete('fish', where: 'fish_id = ?', whereArgs: [id]);
  }

  Future<List<Fish>> getFishList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('fish');

    return List.generate(maps.length, (i) {
      return Fish(
        id: maps[i]['fish_id'],
        speed: maps[i]['speed'],
        color: Color(int.parse(maps[i]['color'], radix: 16)),
      );
    });
  }
}
