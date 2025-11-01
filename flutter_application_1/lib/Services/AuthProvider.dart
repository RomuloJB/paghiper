import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Services/AuthService.dart';
import 'package:flutter_application_1/Banco/entidades/User.dart';
import 'package:flutter_application_1/Banco/entidades/Company.dart';

/// Provider que gerencia o estado de autenticação da aplicação
///
/// Responsabilidades:
/// - Manter o usuário logado em memória
/// - Persistir sessão usando SharedPreferences
/// - Controlar login/logout
/// - Verificar permissões baseadas em role
class AuthProvider extends ChangeNotifier {
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUserRole = 'auth_user_role';
  static const String _keyCompanyId = 'auth_company_id';
  static const String _keyCompanyName = 'auth_company_name';

  User? _currentUser;
  Company? _currentCompany;
  bool _isLoading = true;
  bool _isInitialized = false;

  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  // Getters públicos
  User? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Helpers de permissão
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isUser => _currentUser?.isUser ?? false;
  bool get hasCompany => _currentCompany != null;

  String get userName => _currentUser?.name ?? 'Usuário';
  String get userEmail => _currentUser?.email ?? '';
  String get companyName => _currentCompany?.name ?? 'Sem empresa';
  int? get userId => _currentUser?.id;
  int? get companyId => _currentUser?.companyId;

  /// Inicializa o provider, tentando restaurar sessão salva
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _restoreSession();
    } catch (e) {
      debugPrint('Erro ao restaurar sessão: $e');
      await clearSession();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Tenta restaurar sessão do SharedPreferences
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt(_keyUserId);
    final userEmail = prefs.getString(_keyUserEmail);
    final userName = prefs.getString(_keyUserName);
    final userRole = prefs.getString(_keyUserRole);
    final companyId = prefs.getInt(_keyCompanyId);
    final companyName = prefs.getString(_keyCompanyName);

    // Se não tiver dados salvos, não há sessão
    if (userId == null || userEmail == null) {
      return;
    }

    // Reconstrói o usuário dos dados salvos
    _currentUser = User(
      id: userId,
      email: userEmail,
      name: userName,
      role: userRole ?? 'user',
      companyId: companyId,
    );

    // Reconstrói a empresa se houver
    if (companyId != null && companyName != null) {
      _currentCompany = Company(
        id: companyId,
        name: companyName,
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    debugPrint('Sessão restaurada para: $userName ($userEmail)');
  }

  /// Faz login do usuário
  Future<void> signIn(String email, String password,
      {bool rememberMe = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signIn(email, password);

      _currentUser = result.user;
      _currentCompany = result.company;

      // Salva sessão se rememberMe estiver ativo
      if (rememberMe) {
        await _saveSession();
      }

      debugPrint(
          'Login bem-sucedido: ${result.user.name} (${result.user.role})');
    } catch (e) {
      debugPrint('Erro no login: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Salva a sessão no SharedPreferences
  Future<void> _saveSession() async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyUserId, _currentUser!.id!);
    await prefs.setString(_keyUserEmail, _currentUser!.email!);
    await prefs.setString(_keyUserRole, _currentUser!.role);

    if (_currentUser!.name != null) {
      await prefs.setString(_keyUserName, _currentUser!.name!);
    }

    if (_currentUser!.companyId != null) {
      await prefs.setInt(_keyCompanyId, _currentUser!.companyId!);
    }

    if (_currentCompany?.name != null) {
      await prefs.setString(_keyCompanyName, _currentCompany!.name);
    }

    debugPrint('Sessão salva com sucesso');
  }

  /// Faz logout do usuário
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await clearSession();
      _currentUser = null;
      _currentCompany = null;

      debugPrint('Logout realizado com sucesso');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpa a sessão salva
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyCompanyId);
    await prefs.remove(_keyCompanyName);
  }

  /// Verifica se o usuário tem uma permissão específica
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    // Admins têm todas as permissões
    if (_currentUser!.isAdmin) return true;

    // Mapeamento de permissões por role
    final userPermissions = <String>[
      'view_contracts',
      'upload_contracts',
      'view_own_data',
    ];

    final adminPermissions = <String>[
      ...userPermissions,
      'manage_users',
      'manage_companies',
      'view_all_contracts',
      'delete_contracts',
      'view_reports',
    ];

    final allowedPermissions =
        _currentUser!.isAdmin ? adminPermissions : userPermissions;

    return allowedPermissions.contains(permission);
  }

  /// Verifica se pode acessar contratos de uma empresa específica
  bool canAccessCompany(int? companyId) {
    if (_currentUser == null) return false;

    // Admin pode acessar qualquer empresa
    if (_currentUser!.isAdmin) return true;

    // Usuário comum só acessa sua própria empresa
    return _currentUser!.companyId == companyId;
  }

  /// Atualiza os dados do usuário atual (útil após edição de perfil)
  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    _saveSession(); // Atualiza sessão
    notifyListeners();
  }

  /// Atualiza os dados da empresa atual
  void updateCurrentCompany(Company? updatedCompany) {
    _currentCompany = updatedCompany;
    _saveSession(); // Atualiza sessão
    notifyListeners();
  }
}
