import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._constructor();
  static DatabaseService get instance => _instance;

  DatabaseService._constructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      final dbFactory = databaseFactoryFfiWeb;
      print('Inicializando banco de dados na web (em memória)');
      return await dbFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
        ),
      );
    } else {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'apollo.db');
      print('Inicializando banco de dados local: $path');
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
        ),
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Atualizando banco de $oldVersion para $newVersion');

    if (oldVersion < 2) {
      print('Criando tabela processing_protocols...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS processing_protocols (
          protocol_code TEXT PRIMARY KEY,
          contract_id TEXT NOT NULL,
          status TEXT NOT NULL,
          current_step TEXT,
          progress INTEGER,
          file_name TEXT,
          created_at TEXT NOT NULL,
          completed_at TEXT,
          error_message TEXT,
          FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Criando tabelas para a versão $version do banco de dados...');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        company_id INTEGER,
        created_at TEXT,
        FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');
    await db.execute('CREATE INDEX idx_users_company ON users(company_id)');

    await db.execute('''
      CREATE TABLE contract_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE corporate_regimes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE society_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE contracts (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        filename TEXT NOT NULL,
        hash TEXT UNIQUE,
        uploaded_at TEXT NOT NULL,
        processed_at TEXT,
        status TEXT NOT NULL,
        company_name TEXT,
        cnpj TEXT,
        foundation_date TEXT,
        capital_social REAL,
        address TEXT,
        contract_type_id INTEGER,
        corporate_regime_id INTEGER,
        society_type_id INTEGER,
        confidence REAL,
        raw_json TEXT,
        notes TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL,
        FOREIGN KEY(contract_type_id) REFERENCES contract_types(id),
        FOREIGN KEY(corporate_regime_id) REFERENCES corporate_regimes(id),
        FOREIGN KEY(society_type_id) REFERENCES society_types(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE partners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id TEXT NOT NULL,
        name TEXT NOT NULL,
        cpf_cnpj TEXT,
        qualification TEXT,
        role TEXT,
        quota_percent REAL,
        capital_subscribed REAL,
        address TEXT,
        FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE contract_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id TEXT NOT NULL,
        change_date TEXT NOT NULL,
        change_type TEXT,
        description TEXT NOT NULL,
        FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE capital_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        value REAL NOT NULL,
        FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE processing_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id TEXT NOT NULL,
        step TEXT NOT NULL,
        message TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE processing_protocols (
        protocol_code TEXT PRIMARY KEY,
        contract_id TEXT NOT NULL,
        status TEXT NOT NULL,
        current_step TEXT,
        progress INTEGER,
        file_name TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        error_message TEXT,
        FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cnpj TEXT UNIQUE NOT NULL,
        created_at TEXT,
        hash TEXT UNIQUE
      )
    ''');

    // ========== SEED DOS DADOS ==========

    // 1. Seed admin
    final adminId = await db.insert('users', {
      'name': 'Admin Sistema',
      'email': 'admin@admin.com',
      'password': 'admin123',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });
    print('Admin inserido com ID: $adminId');

    final userId = await db.insert('users', {
      'name': 'normal user',
      'email': 'user@user.com',
      'password': 'user123',
      'role': 'user',
      'created_at': DateTime.now().toIso8601String(),
    });
    print('user inserido com ID: $userId');

    // 2. Seed das tabelas de lookup
    print('Inserindo dados nas tabelas de lookup...');

    // Contract Types
    await db.insert('contract_types', {'name': 'MEI'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('contract_types', {'name': 'SA'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('contract_types', {'name': 'EIRELI'},
        conflictAlgorithm: ConflictAlgorithm.ignore);

    // Corporate Regimes
    await db.insert('corporate_regimes', {'name': 'Lucro Presumido'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('corporate_regimes', {'name': 'Lucro Real'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('corporate_regimes', {'name': 'Simples Nacional'},
        conflictAlgorithm: ConflictAlgorithm.ignore);

    // Society Types
    await db.insert('society_types', {'name': 'Sociedade Simples'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('society_types', {'name': 'Sociedade Anônima'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('society_types', {'name': 'Sociedade Limitada'},
        conflictAlgorithm: ConflictAlgorithm.ignore);

    //Company
    await db.insert('companies', {'name': 'PagHiper'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('companies', {'cnpj': '11222333444455'},
        conflictAlgorithm: ConflictAlgorithm.ignore);

    // 3. Seed das empresas
    print('Inserindo empresas...');
    final companyIds = <String, int>{};

    // Empresa Beta
    final betaCompanyId = await db.insert('companies', {
      'name': 'Empresa Beta ME',
      'cnpj': '98.765.432/0001-55',
      'created_at': DateTime.now().toIso8601String(),
    });
    companyIds['2'] = betaCompanyId;

    // Empresa Gamma
    final gammaCompanyId = await db.insert('companies', {
      'name': 'Empresa Gamma SA',
      'cnpj': '11.111.111/0001-11',
      'created_at': DateTime.now().toIso8601String(),
    });
    companyIds['3'] = gammaCompanyId;

    // Empresa Delta
    final deltaCompanyId = await db.insert('companies', {
      'name': 'Empresa Delta EIRELI',
      'cnpj': '55.444.333/0001-77',
      'created_at': DateTime.now().toIso8601String(),
    });
    companyIds['4'] = deltaCompanyId;

    // 4. Seed dos contratos
    print('Inserindo contratos...');

    // Contrato 2 - Empresa Beta
    final contractTypeMEI = await db
        .rawQuery("SELECT id FROM contract_types WHERE name = ?", ['MEI']);
    final regimePresumido = await db.rawQuery(
        "SELECT id FROM corporate_regimes WHERE name = ?", ['Lucro Presumido']);
    final societySimples = await db.rawQuery(
        "SELECT id FROM society_types WHERE name = ?", ['Sociedade Simples']);

    await db.insert('contracts', {
      'id': '2',
      'user_id': adminId.toString(),
      'filename': 'contrato_empresa_beta.pdf',
      'hash': 'hash_beta_456',
      'uploaded_at': '2025-04-18T09:00:00',
      'processed_at': '2025-10-02T14:22:15',
      'status': 'pending',
      'company_name': 'Empresa Beta ME',
      'cnpj': '98.765.432/0001-55',
      'foundation_date': null,
      'capital_social': 150000.00,
      'address': null,
      'contract_type_id':
          contractTypeMEI.isNotEmpty ? contractTypeMEI.first['id'] : null,
      'corporate_regime_id':
          regimePresumido.isNotEmpty ? regimePresumido.first['id'] : null,
      'society_type_id':
          societySimples.isNotEmpty ? societySimples.first['id'] : null,
      'confidence': null,
      'raw_json': null,
      'notes': null,
    });

    // Contrato 3 - Empresa Gamma
    final contractTypeSA = await db
        .rawQuery("SELECT id FROM contract_types WHERE name = ?", ['SA']);
    final regimeReal = await db.rawQuery(
        "SELECT id FROM corporate_regimes WHERE name = ?", ['Lucro Real']);
    final societyAnonima = await db.rawQuery(
        "SELECT id FROM society_types WHERE name = ?", ['Sociedade Anônima']);

    await db.insert('contracts', {
      'id': '3',
      'user_id': adminId.toString(),
      'filename': 'contrato_empresa_gamma.pdf',
      'hash': 'hash_gamma_789',
      'uploaded_at': '2025-05-10T15:30:00',
      'processed_at': '2025-09-10T15:32:00',
      'status': 'processed',
      'company_name': 'Empresa Gamma SA',
      'cnpj': '11.111.111/0001-11',
      'foundation_date': null,
      'capital_social': 2000000.00,
      'address': null,
      'contract_type_id':
          contractTypeSA.isNotEmpty ? contractTypeSA.first['id'] : null,
      'corporate_regime_id':
          regimeReal.isNotEmpty ? regimeReal.first['id'] : null,
      'society_type_id':
          societyAnonima.isNotEmpty ? societyAnonima.first['id'] : null,
      'confidence': null,
      'raw_json': null,
      'notes': null,
    });

    // Contrato 4 - Empresa Delta
    final contractTypeEIRELI = await db
        .rawQuery("SELECT id FROM contract_types WHERE name = ?", ['EIRELI']);
    final regimeSimples = await db.rawQuery(
        "SELECT id FROM corporate_regimes WHERE name = ?",
        ['Simples Nacional']);
    final societyLimitada = await db.rawQuery(
        "SELECT id FROM society_types WHERE name = ?", ['Sociedade Limitada']);

    await db.insert('contracts', {
      'id': '4',
      'user_id': adminId.toString(),
      'filename': 'contrato_empresa_delta.pdf',
      'hash': 'hash_delta_101',
      'uploaded_at': '2025-06-05T08:45:00',
      'processed_at': '2025-09-05T08:50:00',
      'status': 'failed',
      'company_name': 'Empresa Delta EIRELI',
      'cnpj': '55.444.333/0001-77',
      'foundation_date': null,
      'capital_social': 100000.00,
      'address': null,
      'contract_type_id':
          contractTypeEIRELI.isNotEmpty ? contractTypeEIRELI.first['id'] : null,
      'corporate_regime_id':
          regimeSimples.isNotEmpty ? regimeSimples.first['id'] : null,
      'society_type_id':
          societyLimitada.isNotEmpty ? societyLimitada.first['id'] : null,
      'confidence': null,
      'raw_json': null,
      'notes': 'Falha no OCR do PDF.',
    });

    // 5. Seed dos sócios
    print('Inserindo sócios...');

    // Sócio do Contrato 2 (Beta)
    await db.insert('partners', {
      'contract_id': '2',
      'name': 'Carlos Mendes',
      'cpf_cnpj': '111.222.333-44',
      'qualification': null,
      'role': 'Sócio administrador',
      'quota_percent': 100.0,
      'capital_subscribed': null,
      'address': null,
    });

    // Sócios do Contrato 3 (Gamma)
    await db.insert('partners', {
      'contract_id': '3',
      'name': 'Investimentos XYZ Ltda',
      'cpf_cnpj': '22.222.222/0001-22',
      'qualification': null,
      'role': 'Acionista majoritário',
      'quota_percent': 75.0,
      'capital_subscribed': null,
      'address': null,
    });

    await db.insert('partners', {
      'contract_id': '3',
      'name': 'Fernanda Souza',
      'cpf_cnpj': '333.444.555-66',
      'qualification': null,
      'role': 'Acionista',
      'quota_percent': 25.0,
      'capital_subscribed': null,
      'address': null,
    });

    // Sócia do Contrato 4 (Delta)
    await db.insert('partners', {
      'contract_id': '4',
      'name': 'Ana Pereira',
      'cpf_cnpj': '777.888.999-00',
      'qualification': null,
      'role': 'Única sócia',
      'quota_percent': 100.0,
      'capital_subscribed': null,
      'address': null,
    });

    await db.insert('users', {
      'name': 'Romulo',
      'email': 'rom@gmail.com',
      'password': 'aaaaaa',
      'role': 'user',
      'company_id': 4
    });

    await db.insert('users', {
      'name': 'Gabriela',
      'email': 'gab@gmail.com',
      'password': 'aaaaaa',
      'role': 'user',
      'company_id': 4
    });

    await db.insert('users', {
      'name': 'Caue',
      'email': 'cau@gmail.com',
      'password': 'aaaaaa',
      'role': 'user',
      'company_id': 4
    });

    await db.insert('users', {
      'name': 'Maria',
      'email': 'mar@gmail.com',
      'password': 'aaaaaa',
      'role': 'user',
      'company_id': 3
    });

    await db.insert('users', {
      'name': 'Joao',
      'email': 'joa@gmail.com',
      'password': 'aaaaaa',
      'role': 'user',
      'company_id': 3
    });

    await db.insert('users', {
      'name': 'Rafael',
      'email': 'raf@gmail.com',
      'password': 'aaaaaa',
      'role': 'user',
      'company_id': 5
    });

    await db.insert('users', {
      'name': 'Ariel',
      'email': 'ari@gmail.com',
      'password': 'aaaaaa',
      'role': 'user',
      'company_id': 5
    });

    print('Seed completo! 3 contratos e 4 sócios inseridos com sucesso!');
    print('Tabelas criadas com sucesso!');
  }
}
