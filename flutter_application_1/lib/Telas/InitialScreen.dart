import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/Services/AuthProvider.dart';
import 'package:flutter_application_1/Routes/rotas.dart';

/// Tela inicial que decide para onde direcionar o usuário
/// - Se autenticado: vai para unified contract
/// - Se não autenticado: vai para login
class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Enquanto está inicializando, mostra loading
        if (auth.isLoading || !auth.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando...'),
                ],
              ),
            ),
          );
        }

        // Após inicializar, redireciona
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (auth.isAuthenticated) {
            Navigator.of(context).pushReplacementNamed(Rotas.unifiedContract);
          } else {
            Navigator.of(context).pushReplacementNamed(Rotas.login);
          }
        });

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
