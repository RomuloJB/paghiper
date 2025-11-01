import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/Services/AuthProvider.dart';
import 'package:flutter_application_1/Routes/rotas.dart';

/// Widget que mostra informações do usuário logado
/// Pode ser usado em Drawer, AppBar ou outras partes da UI
class UserInfoWidget extends StatelessWidget {
  final bool showLogoutButton;
  final bool compact;

  const UserInfoWidget({
    super.key,
    this.showLogoutButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const SizedBox.shrink();
        }

        if (compact) {
          return _buildCompactView(context, auth);
        }

        return _buildFullView(context, auth);
      },
    );
  }

  Widget _buildCompactView(BuildContext context, AuthProvider auth) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: auth.isAdmin ? Colors.red : Colors.blue,
        child: Text(
          auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        auth.userName,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        auth.isAdmin ? 'Administrador' : 'Usuário',
        style: TextStyle(
          fontSize: 12,
          color: auth.isAdmin ? Colors.red : Colors.grey,
        ),
      ),
      trailing: showLogoutButton
          ? IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _handleLogout(context, auth),
              tooltip: 'Sair',
            )
          : null,
    );
  }

  Widget _buildFullView(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: auth.isAdmin ? Colors.red : Colors.blue,
                child: Text(
                  auth.userName.isNotEmpty
                      ? auth.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.badge,
            'Perfil',
            auth.isAdmin ? 'Administrador' : 'Usuário',
            auth.isAdmin ? Colors.red : Colors.blue,
          ),
          if (auth.hasCompany) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.business,
              'Empresa',
              auth.companyName,
              Colors.green,
            ),
          ],
          if (showLogoutButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context, auth),
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text('Deseja realmente sair do sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Rotas.login,
          (route) => false,
        );
      }
    }
  }
}

/// Widget para mostrar badge de permissões/role
class PermissionBadge extends StatelessWidget {
  final String permission;
  final bool granted;

  const PermissionBadge({
    super.key,
    required this.permission,
    this.granted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        granted ? Icons.check_circle : Icons.cancel,
        color: granted ? Colors.green : Colors.red,
        size: 16,
      ),
      label: Text(
        permission,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: granted ? Colors.green.shade50 : Colors.red.shade50,
    );
  }
}

/// Widget para verificar e exibir conteúdo baseado em permissão
class PermissionWidget extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.hasPermission(permission)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
