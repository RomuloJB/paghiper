import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/Services/AuthProvider.dart';
import 'package:flutter_application_1/Services/AuthService.dart';
import 'package:flutter_application_1/Banco/entidades/User.dart';
import 'package:flutter_application_1/Banco/entidades/Company.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() async {
      // Limpa SharedPreferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
      await authProvider.initialize();
    });

    test('Deve iniciar sem usuário autenticado', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.isAdmin, false);
      expect(authProvider.isUser, false);
    });

    test('Deve identificar permissões corretamente', () {
      // Simula um usuário comum
      authProvider.updateCurrentUser(
        const User(
          id: 1,
          name: 'User Teste',
          email: 'user@teste.com',
          role: 'user',
        ),
      );

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isUser, true);
      expect(authProvider.isAdmin, false);
      expect(authProvider.hasPermission('view_contracts'), true);
      expect(authProvider.hasPermission('manage_users'), false);
    });

    test('Admin deve ter todas as permissões', () {
      // Simula um admin
      authProvider.updateCurrentUser(
        const User(
          id: 1,
          name: 'Admin Teste',
          email: 'admin@teste.com',
          role: 'admin',
        ),
      );

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isAdmin, true);
      expect(authProvider.hasPermission('view_contracts'), true);
      expect(authProvider.hasPermission('manage_users'), true);
      expect(authProvider.hasPermission('delete_contracts'), true);
      expect(authProvider.hasPermission('qualquer_permissao'), true);
    });

    test('Deve verificar acesso à empresa corretamente', () {
      // User comum com empresa ID 1
      authProvider.updateCurrentUser(
        const User(
          id: 1,
          name: 'User Teste',
          email: 'user@teste.com',
          role: 'user',
          companyId: 1,
        ),
      );

      expect(authProvider.canAccessCompany(1), true);
      expect(authProvider.canAccessCompany(2), false);

      // Admin pode acessar qualquer empresa
      authProvider.updateCurrentUser(
        const User(
          id: 2,
          name: 'Admin Teste',
          email: 'admin@teste.com',
          role: 'admin',
          companyId: 1,
        ),
      );

      expect(authProvider.canAccessCompany(1), true);
      expect(authProvider.canAccessCompany(2), true);
      expect(authProvider.canAccessCompany(999), true);
    });

    test('Deve limpar dados no logout', () async {
      // Simula login
      authProvider.updateCurrentUser(
        const User(
          id: 1,
          name: 'User Teste',
          email: 'user@teste.com',
          role: 'user',
        ),
      );

      expect(authProvider.isAuthenticated, true);

      // Faz logout
      await authProvider.signOut();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.currentUser, null);
    });

    test('Deve retornar informações do usuário corretamente', () {
      authProvider.updateCurrentUser(
        const User(
          id: 1,
          name: 'João Silva',
          email: 'joao@teste.com',
          role: 'user',
          companyId: 5,
        ),
      );

      authProvider.updateCurrentCompany(
        const Company(
          id: 5,
          name: 'Empresa Teste LTDA',
          createdAt: '2024-01-01',
        ),
      );

      expect(authProvider.userName, 'João Silva');
      expect(authProvider.userEmail, 'joao@teste.com');
      expect(authProvider.userId, 1);
      expect(authProvider.companyId, 5);
      expect(authProvider.companyName, 'Empresa Teste LTDA');
      expect(authProvider.hasCompany, true);
    });
  });

  group('AuthService Integration Tests', () {
    // Nota: Estes testes requerem um banco de dados configurado
    // São testes de integração, não unitários

    test('Deve validar credenciais inválidas', () async {
      final authService = AuthService();

      expect(
        () async =>
            await authService.signIn('invalido@email.com', 'senhaerrada'),
        throwsA(isA<Exception>()),
      );
    });

    // Adicione mais testes de integração conforme necessário
  });

  group('Permission System Tests', () {
    test('Deve mapear permissões de user corretamente', () {
      final authProvider = AuthProvider();
      authProvider.updateCurrentUser(
        const User(
          id: 1,
          name: 'User',
          email: 'user@teste.com',
          role: 'user',
        ),
      );

      final userPermissions = [
        'view_contracts',
        'upload_contracts',
        'view_own_data',
      ];

      for (final permission in userPermissions) {
        expect(
          authProvider.hasPermission(permission),
          true,
          reason: 'User deveria ter permissão: $permission',
        );
      }

      final deniedPermissions = [
        'manage_users',
        'manage_companies',
        'delete_contracts',
      ];

      for (final permission in deniedPermissions) {
        expect(
          authProvider.hasPermission(permission),
          false,
          reason: 'User NÃO deveria ter permissão: $permission',
        );
      }
    });

    test('Deve mapear permissões de admin corretamente', () {
      final authProvider = AuthProvider();
      authProvider.updateCurrentUser(
        const User(
          id: 1,
          name: 'Admin',
          email: 'admin@teste.com',
          role: 'admin',
        ),
      );

      final allPermissions = [
        'view_contracts',
        'upload_contracts',
        'view_own_data',
        'manage_users',
        'manage_companies',
        'delete_contracts',
        'view_reports',
        'qualquer_coisa', // Admin tem TODAS as permissões
      ];

      for (final permission in allPermissions) {
        expect(
          authProvider.hasPermission(permission),
          true,
          reason: 'Admin deveria ter permissão: $permission',
        );
      }
    });
  });
}
