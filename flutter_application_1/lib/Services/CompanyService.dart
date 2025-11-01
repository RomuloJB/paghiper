import 'package:flutter_application_1/Banco/DAO/CompanyDAO.dart';
import 'package:flutter_application_1/Banco/DAO/UserDAO.dart';
import 'package:flutter_application_1/Banco/entidades/Company.dart';
import 'package:flutter_application_1/Banco/entidades/User.dart';

class CompanyService {
  final CompanyDao _companyDao;
  final UserDao _userDao;

  CompanyService({
    CompanyDao? companyDao,
    UserDao? userDao,
  })  : _companyDao = companyDao ?? CompanyDao(),
        _userDao = userDao ?? UserDao();

  /// Criar empresa (apenas admin pode)
  Future<Company> createCompany({
    required String name,
    String? cnpj,
    required int? adminUserId,
    String? hash,
  }) async {
    // Validar se CNPJ já existe
    if (cnpj != null) {
      final existing = await _companyDao.findByCnpj(cnpj);
      if (existing != null) {
        throw Exception('CNPJ já cadastrado');
      }
    }

    // Criar empresa
    final company = Company(
      name: name,
      cnpj: cnpj,
      createdAt: DateTime.now().toIso8601String(),
    );

    final companyId = await _companyDao.create(company);

    // Associar admin à empresa
    final admin = await _userDao.read(adminUserId!);
    if (admin == null) {
      throw Exception('Usuário admin não encontrado');
    }

    await _userDao.update(admin.copyWith(companyId: companyId));

    return company.copyWith(id: companyId);
  }

  /// Listar funcionários de uma empresa (apenas admin da empresa pode)
  Future<List<User>> listEmployees(int companyId, int requestingUserId) async {
    // Validar permissão
    final requestingUser = await _userDao.read(requestingUserId);
    if (requestingUser == null) {
      throw Exception('Usuário não encontrado');
    }
    if (!requestingUser.isAdmin) {
      throw Exception('Apenas administradores podem listar funcionários');
    }

    return await _userDao.findEmployeesByCompany(companyId);
  }

  /// Adicionar funcionário à empresa
  Future<User> addEmployee({
    required int companyId,
    required String name,
    required String email,
    required String password,
    required int requestingUserId,
  }) async {
    // Validar permissão do admin
    final requestingUser = await _userDao.read(requestingUserId);
    if (requestingUser == null) {
      throw Exception('Usuário não encontrado');
    }
    if (!requestingUser.isAdmin) {
      throw Exception('Apenas administradores podem adicionar funcionários');
    }

    // Validar email duplicado
    if (await _userDao.emailExists(email)) {
      throw Exception('E-mail já cadastrado');
    }

    // Criar funcionário
    final employee = User(
      name: name,
      email: email.trim().toLowerCase(),
      password: password,
      role: 'user',
      companyId: companyId,
      createdAt: DateTime.now().toIso8601String(),
    );

    final employeeId = await _userDao.create(employee);
    return employee.copyWith(id: employeeId);
  }

  /// Remover funcionário da empresa
  Future<void> removeEmployee(int employeeId, int requestingUserId) async {
    final employee = await _userDao.read(employeeId);
    if (employee == null) {
      throw Exception('Funcionário não encontrado');
    }

    final requestingUser = await _userDao.read(requestingUserId);
    if (requestingUser == null) {
      throw Exception('Usuário não encontrado');
    }
    if (!requestingUser.isAdmin) {
      throw Exception('Apenas administradores podem remover funcionários');
    }

    if (employee.isAdmin) {
      throw Exception('Não é possível remover o admin da empresa');
    }

    await _userDao.delete(employeeId);
  }

  /// Obter detalhes da empresa
  Future<Company?> getCompany(int companyId) async {
    return await _companyDao.read(companyId);
  }

  /// Obter empresa do usuário logado
  Future<Company?> getUserCompany(int userId) async {
    final user = await _userDao.read(userId);
    if (user?.companyId == null) return null;
    return await _companyDao.read(user!.companyId!);
  }
}
