import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqlite_crud/constants/app_constants.dart';
import 'package:sqlite_crud/constants/sq_lite_constants.dart';

class DatabaseHelper {
  static Future<sql.Database> db() async {
    return sql.openDatabase(
      AppConstants.DB_NAME,
      version: AppConstants.DB_VERSION,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  /**
      id: the id of a item
      title, description: name and description of  activity
      created_at: the time that the item was created. It will be automatically handled by SQLite
      **/
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE ${SqLiteConstants.TABLE_ITEMS}(
        ${SqLiteConstants.TABLE_ID} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        ${SqLiteConstants.TABLE_TITLE} TEXT,
        ${SqLiteConstants.TABLE_DESCRIPTION} TEXT,
        ${SqLiteConstants.TABLE_CREATED_AT} TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
  }

  // Creates new item
  static Future<int> createItem(String? title, String? descrption) async {
    final db = await DatabaseHelper.db();

    final data = {
      SqLiteConstants.TABLE_TITLE: title,
      SqLiteConstants.TABLE_DESCRIPTION: descrption
    };
    final id = await db.insert(SqLiteConstants.TABLE_ITEMS, data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;

    /*When a UNIQUE constraint violation occurs, the pre-existing rows that are causing the constraint violation
    are removed prior to inserting or updating the current row. Thus the insert or update always occurs.*/
  }

  // Read all items
  static Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final db = await DatabaseHelper.db();
      return db.query('items', orderBy: "id");
    } on Exception {
      return [];
    }
  }

  /*Get a single item by id
  We dont use this method, it is for you if you want it.*/
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await DatabaseHelper.db();
    return db.query('items', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an item by id
  static Future<int> updateItem(
      int id, String title, String? descrption) async {
    final db = await DatabaseHelper.db();

    final data = {
      SqLiteConstants.TABLE_TITLE: title,
      SqLiteConstants.TABLE_DESCRIPTION: descrption,
      SqLiteConstants.TABLE_CREATED_AT: DateTime.now().toString()
    };

    final result = await db.update(SqLiteConstants.TABLE_ITEMS, data,
        where: "${SqLiteConstants.TABLE_ID} = ?", whereArgs: [id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int id) async {
    final db = await DatabaseHelper.db();
    try {
      await db.delete(SqLiteConstants.TABLE_ITEMS,
          where: "${SqLiteConstants.TABLE_ID} = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }
}
