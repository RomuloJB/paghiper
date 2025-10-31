import 'package:flutter/material.dart';
import 'package:flutter_application_1/Services/AuthService.dart';
import 'package:flutter_application_1/Componentes/Formularios/FormLogin.dart';
import 'package:flutter_application_1/Routes/rotas.dart';
import 'package:flutter_application_1/Telas/cadastro/WidgetCadastro.dart';

class WidgetLogin extends StatelessWidget {
  const WidgetLogin({super.key});

  Future<void> _onSubmit(
    BuildContext context,
    String email,
    String password,
    bool rememberMe,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Preencha e-mail e senha.');
    }

    final auth = AuthService();
    await auth.signIn(email, password);

    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(Rotas.unifiedContract);
    }
  }

  void _onForgotPassword(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: const Text(
          'Enviamos um link de recuperação para o seu e-mail (exemplo).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _goToCadastro(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WidgetCadastro()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0857C3), Color(0xFF0860DB), Color(0xFF24d17a)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 480 : 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PagHiper',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Análise Inteligente de Contratos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(isDesktop ? 40 : 32),
                        child: LoginForm(
                          onSubmit: (email, password, rememberMe) =>
                              _onSubmit(context, email, password, rememberMe),
                          onForgotPassword: () => _onForgotPassword(context),
                          onRegister: () => _goToCadastro(context),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '© 2025 Cocão - Todos os direitos reservados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
