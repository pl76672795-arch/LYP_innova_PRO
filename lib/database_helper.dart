import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseHelper - Base de datos central P&L Innova
/// NO MODIFICAR tablas/columnas existentes de registros (respeto al sudor previo)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('innova_pro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  /// Tabla original registros - INTACTA (P&L, Galería)
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE registros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL,
        categoria TEXT,
        fecha TEXT
      )
    ''');
    await _createTablesExtendidas(db);
  }

  Future _upgradeDB(Database db, int oldV, int newV) async {
    if (oldV < 2) await _createTablesExtendidas(db);
    if (oldV < 3) await _migrateV3(db);
  }

  Future _migrateV3(Database db) async {
    try {
      await db.execute('ALTER TABLE gastos_caja_chica ADD COLUMN firebase_id TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE metrado_acero ADD COLUMN firebase_id TEXT');
    } catch (_) {}
    await db.execute('''
      CREATE TABLE IF NOT EXISTS galeria_fotos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path_local TEXT,
        url_cloud TEXT,
        timestamp TEXT,
        fecha TEXT
      )
    ''');
  }

  /// Tablas nuevas - expansión sin tocar las existentes
  Future _createTablesExtendidas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gastos_caja_chica (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monto REAL NOT NULL,
        descripcion TEXT,
        origen TEXT,
        fecha TEXT,
        foto_path TEXT,
        firebase_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS metrado_acero (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cantidad_varillas INTEGER,
        diametro_mm REAL,
        longitud_m REAL,
        peso_kg REAL,
        costo_soles REAL,
        fecha TEXT,
        firebase_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS galeria_fotos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path_local TEXT,
        url_cloud TEXT,
        timestamp TEXT,
        fecha TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS config_obra (
        clave TEXT PRIMARY KEY,
        valor TEXT
      )
    ''');
    // Valorización por defecto si no existe
    await db.rawInsert(
      'INSERT OR IGNORE INTO config_obra (clave, valor) VALUES (?, ?)',
      ['valorizacion_soles', '245600.00'],
    );

    // --- TABLAS AGREGADAS PARA SINCRONIZACIÓN CON FIREBASE ---
    await db.execute('''
      CREATE TABLE IF NOT EXISTS albanileria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        tipo_muro TEXT,
        largo REAL,
        alto REAL,
        ladrillos INTEGER,
        mortero REAL,
        fecha TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS concreto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        resistencia TEXT,
        bolsas_cemento INTEGER,
        arena REAL,
        piedra REAL,
        fecha TEXT
      )
    ''');
    // Agregada tabla presupuestos para pedido 5
    await db.execute('''
      CREATE TABLE IF NOT EXISTS presupuestos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_id TEXT UNIQUE,
        descripcion TEXT,
        monto_total REAL,
        detalles TEXT,
        fecha TEXT
      )
    ''');
  }

  // --- GASTOS CAJA CHICA ---
  Future<int> insertarGasto(double monto, {String? descripcion, String origen = 'manual', String? fotoPath, String? firebaseId}) async {
    final db = await database;
    return await db.insert('gastos_caja_chica', {
      'monto': monto,
      'descripcion': descripcion ?? 'Sin descripción',
      'origen': origen,
      'fecha': DateTime.now().toIso8601String(),
      'foto_path': fotoPath,
      'firebase_id': firebaseId,
    });
  }

  Future<bool> gastoExistePorFirebaseId(String fid) async {
    final db = await database;
    final r = await db.query('gastos_caja_chica', where: 'firebase_id = ?', whereArgs: [fid], limit: 1);
    return r.isNotEmpty;
  }

  Future<void> marcarGastoFirebaseId(int id, String firebaseId) async {
    final db = await database;
    await db.update('gastos_caja_chica', {'firebase_id': firebaseId}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> marcarMetradoFirebaseId(int id, String firebaseId) async {
    final db = await database;
    await db.update('metrado_acero', {'firebase_id': firebaseId}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarGastosParaSync({int limit = 200}) async {
    final db = await database;
    return await db.query('gastos_caja_chica', orderBy: 'id ASC', limit: limit);
  }

  Future<double> totalGastosCajaChica() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COALESCE(SUM(monto), 0) as total FROM gastos_caja_chica');
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> listarGastos({int limit = 50}) async {
    final db = await database;
    return await db.query('gastos_caja_chica', orderBy: 'id DESC', limit: limit);
  }

  // --- METRADO ACERO ---
  Future<int> insertarMetradoAcero({
    required int cantidadVarillas,
    required double diametroMm,
    required double longitudM,
    required double pesoKg,
    required double costoSoles,
  }) async {
    final db = await database;
    return await db.insert('metrado_acero', {
      'cantidad_varillas': cantidadVarillas,
      'diametro_mm': diametroMm,
      'longitud_m': longitudM,
      'peso_kg': pesoKg,
      'costo_soles': costoSoles,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<double> totalMetrosAcero() async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(cantidad_varillas * longitud_m), 0) as total FROM metrado_acero',
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalPesoAceroKg() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COALESCE(SUM(peso_kg), 0) as total FROM metrado_acero');
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> listarMetradosAcero({int limit = 30}) async {
    final db = await database;
    return await db.query('metrado_acero', orderBy: 'id DESC', limit: limit);
  }

  Future<bool> metradoExistePorFirebaseId(String fid) async {
    final db = await database;
    final r = await db.query('metrado_acero', where: 'firebase_id = ?', whereArgs: [fid], limit: 1);
    return r.isNotEmpty;
  }

  Future<int> insertarMetradoAceroDesdeFirebase({
    required int cantidadVarillas,
    required double diametroMm,
    required double longitudM,
    required double pesoKg,
    required double costoSoles,
    required String firebaseId,
  }) async {
    final db = await database;
    return await db.insert('metrado_acero', {
      'cantidad_varillas': cantidadVarillas,
      'diametro_mm': diametroMm,
      'longitud_m': longitudM,
      'peso_kg': pesoKg,
      'costo_soles': costoSoles,
      'fecha': DateTime.now().toIso8601String(),
      'firebase_id': firebaseId,
    });
  }

  Future<List<Map<String, dynamic>>> listarMetradosAceroParaSync({int limit = 100}) async {
    final db = await database;
    return await db.query('metrado_acero', orderBy: 'id ASC', limit: limit);
  }

  // --- GALERÍA FOTOS ---
  Future<int> insertarFotoGaleria({String? pathLocal, String? urlCloud, required String timestamp}) async {
    final db = await database;
    return await db.insert('galeria_fotos', {
      'path_local': pathLocal,
      'url_cloud': urlCloud,
      'timestamp': timestamp,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<void> actualizarUrlCloudGaleria(int id, String url) async {
    final db = await database;
    await db.update('galeria_fotos', {'url_cloud': url}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarFotosGaleria({int limit = 100}) async {
    final db = await database;
    return await db.query('galeria_fotos', orderBy: 'id DESC', limit: limit);
  }

  Future<bool> fotoGaleriaExistePorTimestamp(String ts) async {
    final db = await database;
    final r = await db.query('galeria_fotos', where: 'timestamp = ?', whereArgs: [ts], limit: 1);
    return r.isNotEmpty;
  }

  Future<int> insertarFotoGaleriaDesdeCloud({required String timestamp, required String url}) async {
    final db = await database;
    return await db.insert('galeria_fotos', {
      'path_local': null,
      'url_cloud': url,
      'timestamp': timestamp,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  // --- CONFIG OBRA (Valorización) ---
  Future<double> valorizacionObra() async {
    final db = await database;
    final r = await db.query('config_obra', where: 'clave = ?', whereArgs: ['valorizacion_soles']);
    if (r.isEmpty) return 245600.00;
    return double.tryParse(r.first['valor']?.toString() ?? '') ?? 245600.00;
  }

  Future<void> actualizarValorizacion(double valor) async {
    final db = await database;
    await db.insert('config_obra', {
      'clave': 'valorizacion_soles',
      'valor': valor.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- MÉTODOS AGREGADOS PARA SINCRONIZACIÓN CON FIREBASE ---
  Future<bool> albanileriaExistePorFirebaseId(String firebaseId) async {
    final db = await database;
    final result = await db.query('albanileria', where: 'firebase_id = ?', whereArgs: [firebaseId]);
    return result.isNotEmpty;
  }

  Future<void> insertarAlbanileriaDesdeFirebase(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('albanileria', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> concretoExistePorFirebaseId(String firebaseId) async {
    final db = await database;
    final result = await db.query('concreto', where: 'firebase_id = ?', whereArgs: [firebaseId]);
    return result.isNotEmpty;
  }

  Future<void> insertarConcretoDesdeFirebase(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('concreto', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- MÉTODOS AGREGADOS PARA PRESUPUESTOS (PEDIDO 5) ---
  Future<bool> presupuestoExistePorFirebaseId(String firebaseId) async {
    final db = await database;
    final result = await db.query('presupuestos', where: 'firebase_id = ?', whereArgs: [firebaseId]);
    return result.isNotEmpty;
  }

  Future<int> insertarPresupuestoDesdeFirebase(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('presupuestos', data);
  }
} // CIERRE DE LA CLASE