import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/Routes/rotas.dart';
import 'package:flutter_application_1/Services/AuthProvider.dart';

class WidgetDrawer extends StatelessWidget {
  const WidgetDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 233, 233, 233),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF34302D)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          auth.isAdmin ? Colors.red : const Color(0xFF0857C3),
                      child: Text(
                        auth.userName.isNotEmpty
                            ? auth.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      auth.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: auth.isAdmin ? Colors.red : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auth.isAdmin ? 'Administrador' : 'Usuário',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Opções principais
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.of(context).pushNamed(Rotas.unifiedContract);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Novo Contrato'),
                onTap: () {
                  Navigator.of(context).pushNamed(Rotas.upload);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Listar Contratos'),
                onTap: () {
                  Navigator.of(context).pushNamed(Rotas.listagem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Buscar por Protocolo'),
                onTap: () {
                  Navigator.of(context).pushNamed(Rotas.protocolSearch);
                },
              ),

              const Divider(),

              // Opções administrativas (apenas para admins)
              if (auth.isAdmin) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Administração',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.red),
                  title: const Text('Gerenciar Usuários'),
                  onTap: () {
                    Navigator.of(context).pushNamed(Rotas.usersPage);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.red),
                  title: const Text('Gerenciar Empresas'),
                  onTap: () {
                    Navigator.of(context).pushNamed(Rotas.companiesPage);
                  },
                ),
                const Divider(),
              ],

              // Informações adicionais
              if (auth.hasCompany)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Empresa:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        auth.companyName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(),

              // Logout
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sair',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _handleLogout(context, auth),
              ),
            ],
          );
        },
      ),
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
