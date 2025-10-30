import 'package:flutter_application_1/Services/databaseService.dart';
import 'package:flutter_application_1/Banco/entidades/Contract.dart';
import 'package:sqflite/sqflite.dart';

class ContractDao {
  final DatabaseService _dbService = DatabaseService.instance;
  static const String tableName = 'contracts';

  Future<int> create(Contract contract) async {
    final db = await _dbService.database;
    return await db.insert(
      tableName,
      contract.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Contract?> read(String id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Contract.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Contract>> readAll() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    final contracts =
        List.generate(maps.length, (i) => Contract.fromMap(maps[i]));
    return contracts.reversed.toList();
  }

  Future<int> update(Contract contract) async {
    final db = await _dbService.database;
    return await db.update(
      tableName,
      contract.toMap(),
      where: 'id = ?',
      whereArgs: [contract.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _dbService.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Contract>> findByStatus(String status) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: [status],
    );
    return List.generate(maps.length, (i) => Contract.fromMap(maps[i]));
  }

  Future<List<Contract>> findByUser(String userId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Contract.fromMap(maps[i]));
  }

  Future<List<Contract>> findByCompanyName(String name) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'company_name LIKE ?',
      whereArgs: ['%$name%'],
    );
    return List.generate(maps.length, (i) => Contract.fromMap(maps[i]));
  }

  Future<List<Contract>> findByPartnerCount(String partnerCount) async {
    final db = await _dbService.database;
    String whereClause;
    List<dynamic> whereArgs;

    if (partnerCount == '3+') {
      whereClause = '''
        id IN (
          SELECT contract_id 
          FROM partners 
          GROUP BY contract_id 
          HAVING COUNT(*) >= 3
        )
      ''';
      whereArgs = [];
    } else {
      whereClause = '''
        id IN (
          SELECT contract_id 
          FROM partners 
          GROUP BY contract_id 
          HAVING COUNT(*) = ?
        )
      ''';
      whereArgs = [int.parse(partnerCount)];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) => Contract.fromMap(maps[i]));
  }

  /// Busca combinada por vários filtros em uma única query, com suporte a ordenação alfabética.
  /// orderBy: 'alphabetical' => ORDER BY company_name COLLATE NOCASE ASC
  Future<List<Contract>> findByFilters({
    String? name,
    String? cnpjFragment,
    String? status,
    String? partnerCount,
    String? orderBy, // currently supports only 'alphabetical'
  }) async {
    final db = await _dbService.database;

    final List<String> whereParts = [];
    final List<dynamic> args = [];

    if (name != null && name.trim().isNotEmpty) {
      whereParts.add('company_name LIKE ?');
      args.add('%${name.trim()}%');
    }

    if (cnpjFragment != null && cnpjFragment.trim().isNotEmpty) {
      whereParts.add('cnpj LIKE ?');
      args.add('%${cnpjFragment.trim()}%');
    }

    if (status != null && status.trim().isNotEmpty) {
      whereParts.add('status = ?');
      args.add(status.trim());
    }

    // Monta subquery para número de sócios e adiciona argumento (se necessário)
    String partnerSubquery = '';
    if (partnerCount != null && partnerCount.trim().isNotEmpty) {
      if (partnerCount == '3+') {
        partnerSubquery =
            'id IN (SELECT contract_id FROM partners GROUP BY contract_id HAVING COUNT(*) >= 3)';
      } else {
        final parsed = int.tryParse(partnerCount.trim());
        if (parsed != null) {
          partnerSubquery =
              'id IN (SELECT contract_id FROM partners GROUP BY contract_id HAVING COUNT(*) = ?)';
          args.add(parsed);
        }
      }
    }

    String sql = 'SELECT * FROM $tableName';

    if (whereParts.isNotEmpty || partnerSubquery.isNotEmpty) {
      final List<String> allConditions = [...whereParts];
      if (partnerSubquery.isNotEmpty) {
        allConditions.add(partnerSubquery);
      }
      sql = '$sql WHERE ${allConditions.join(' AND ')}';
    }

    // Ordenação: se for "alphabetical", usa nome; senão, mais novos primeiro
    if (orderBy != null && orderBy.isNotEmpty) {
      if (orderBy == 'alphabetical') {
        sql = '$sql ORDER BY company_name COLLATE NOCASE ASC';
      }
    } else {
      // padrão: mais novos primeiro
      sql = '$sql ORDER BY id DESC';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return List.generate(maps.length, (i) => Contract.fromMap(maps[i]));
  }

  Future<List<Contract>> findByCnpjPartial(String fragment) async {
    return await findByFilters(cnpjFragment: fragment);
  }
}
