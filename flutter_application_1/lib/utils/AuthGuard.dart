import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/Services/AuthProvider.dart';
import 'package:flutter_application_1/Routes/rotas.dart';

/// Widget que protege rotas baseado em autenticação e permissões
///
/// Uso:
/// ```dart
/// AuthGuard(
///   child: MinhaTelaProtegida(),
///   requiredPermissions: ['manage_users'], // opcional
///   adminOnly: false, // opcional
/// )
/// ```
class AuthGuard extends StatelessWidget {
  final Widget child;
  final List<String>? requiredPermissions;
  final bool adminOnly;
  final String redirectTo;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredPermissions,
    this.adminOnly = false,
    this.redirectTo = Rotas.login,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Enquanto está carregando, mostra loading
        if (auth.isLoading && !auth.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se não está autenticado, redireciona para login
        if (!auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(redirectTo);
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se requer admin e não é admin
        if (adminOnly && !auth.isAdmin) {
          return _buildAccessDenied(context);
        }

        // Se tem permissões requeridas, verifica cada uma
        if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
          for (final permission in requiredPermissions!) {
            if (!auth.hasPermission(permission)) {
              return _buildAccessDenied(context);
            }
          }
        }

        // Tudo ok, exibe o conteúdo
        return child;
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso Negado'),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Acesso Negado',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Você não tem permissão para acessar esta página.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(Rotas.unifiedContract);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper simples para rotas que requerem apenas autenticação
class AuthenticatedRoute extends StatelessWidget {
  final Widget child;

  const AuthenticatedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AuthGuard(child: child);
  }
}

/// Wrapper para rotas que requerem permissão de admin
class AdminRoute extends StatelessWidget {
  final Widget child;

  const AdminRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      adminOnly: true,
      child: child,
    );
  }
}
