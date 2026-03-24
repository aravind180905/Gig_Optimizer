import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
static Database? _db;

static Future<Database> getDb() async {
if (_db != null) return _db!;

_db = await openDatabase(
  join(await getDatabasesPath(), 'gig_data.db'),
  version: 2, 
  onCreate: (db, version) async {
    await db.execute('''
    CREATE TABLE trip_data(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fare REAL,
      total_distance REAL,
      first_mile REAL,
      last_mile REAL,
      platform TEXT,   -- ✅ FIXED NAME
      created_at TEXT
    )
    ''');
  },

  // HANDLE EXISTING USERS
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE trip_data ADD COLUMN total_distance REAL");
      await db.execute("ALTER TABLE trip_data ADD COLUMN first_mile REAL");
      await db.execute("ALTER TABLE trip_data ADD COLUMN last_mile REAL");
      await db.execute("ALTER TABLE trip_data ADD COLUMN platform TEXT");
    }
  },
);

return _db!;

}

//  INSERT
static Future<void> insertData(
double fare,
double totalDistance,
double firstMile,
double lastMile,
String platform,
) async {
final db = await getDb();

await db.insert(
  'trip_data',
  {
    'fare': fare,
    'total_distance': totalDistance,
    'first_mile': firstMile,
    'last_mile': lastMile,
    'platform': platform,
    'created_at': DateTime.now().toIso8601String(),
  },
);

}

//  GET DATA
static Future<List<Map<String, dynamic>>> getAllData() async {
final db = await getDb();

return await db.query(
  'trip_data',
  orderBy: 'id DESC',
);

}
}
