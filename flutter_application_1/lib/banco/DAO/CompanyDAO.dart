import 'package:flutter_application_1/Services/databaseService.dart';
import 'package:flutter_application_1/Banco/entidades/Company.dart';
import 'package:sqflite/sqflite.dart';

class CompanyDao {
  final DatabaseService _dbService = DatabaseService.instance;
  static const String tableName = 'companies';

  /// Criar nova empresa
  Future<int> create(Company company) async {
    final db = await _dbService.database;
    return await db.insert(tableName, {
      'name': company.name,
      'cnpj': company.cnpj,
      'created_at': company.createdAt,
      'hash': company.hash,
    });
  }

  /// Buscar empresa por ID
  Future<Company?> read(int id) async {
    final db = await _dbService.database;
    final rows = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Company.fromMap(rows.first);
  }

  /// Listar todas as empresas
  Future<List<Company>> readAll() async {
    final db = await _dbService.database;
    final maps = await db.query(tableName, orderBy: 'name ASC');
    return maps.map(Company.fromMap).toList();
  }

  /// Atualizar empresa
  Future<int> update(Company company) async {
    if (company.id == null) {
      throw ArgumentError('company.id não pode ser nulo no update');
    }
    final db = await _dbService.database;
    return await db.update(
      tableName,
      {
        'name': company.name,
        'cnpj': company.cnpj,
        'hash': company.hash,
      },
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  /// Deletar empresa
  Future<int> delete(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Buscar empresa por CNPJ
  Future<Company?> findByCnpj(String cnpj) async {
    final db = await _dbService.database;
    final rows = await db.query(
      tableName,
      where: 'cnpj = ?',
      whereArgs: [cnpj],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Company.fromMap(rows.first);
  }

  /// Contar número de funcionários de uma empresa
  Future<int> countEmployees(int companyId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM users WHERE company_id = ? AND role = "user"',
      [companyId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
