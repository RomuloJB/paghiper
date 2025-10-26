import 'package:flutter/material.dart';
import 'package:flutter_application_1/Banco/entidades/User.dart';
import 'package:flutter_application_1/Services/CompanyService.dart';
import 'package:flutter_application_1/banco/DAO/UserDAO.dart';

/// Widget que exibe a lista de funcionários de uma empresa
class WidgetListaFuncionarios extends StatefulWidget {
  final int companyId;
  final int adminUserId;
  final VoidCallback? onFuncionarioRemovido; // Callback para atualizar lista

  const WidgetListaFuncionarios({
    Key? key,
    required this.companyId,
    required this.adminUserId,
    this.onFuncionarioRemovido,
  }) : super(key: key);

  @override
  State<WidgetListaFuncionarios> createState() =>
      _WidgetListaFuncionariosState();
}

class _WidgetListaFuncionariosState extends State<WidgetListaFuncionarios> {
  final _companyService = CompanyService();
  final _userDao = UserDao();
  List<User> _funcionarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  @override
  void didUpdateWidget(WidgetListaFuncionarios oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega se a empresa mudou
    if (oldWidget.companyId != widget.companyId) {
      _carregarFuncionarios();
    }
  }

  Future<void> _carregarFuncionarios() async {
    setState(() => _isLoading = true);
    try {
      final funcionarios = await _companyService.listEmployees(
        widget.companyId,
        widget.adminUserId,
      );
      if (mounted) {
        setState(() => _funcionarios = funcionarios);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar funcionários: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editarFuncionario(User funcionario) async {
    final nomeController = TextEditingController(text: funcionario.name);
    final emailController = TextEditingController(text: funcionario.email);
    final senhaController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Funcionário'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova Senha (opcional)',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0857C3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (resultado == true) {
      try {
        // Validações
        if (nomeController.text.trim().isEmpty) {
          throw Exception('Nome não pode estar vazio');
        }
        if (emailController.text.trim().isEmpty) {
          throw Exception('E-mail não pode estar vazio');
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
          throw Exception('E-mail inválido');
        }

        // Atualizar funcionário
        final funcionarioAtualizado = funcionario.copyWith(
          name: nomeController.text.trim(),
          email: emailController.text.trim().toLowerCase(),
          password: senhaController.text.isNotEmpty
              ? senhaController.text
              : funcionario
                  .password, // Mantém senha antiga se não informar nova
        );

        await _userDao.update(funcionarioAtualizado);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${funcionarioAtualizado.name} atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );

        _carregarFuncionarios();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
  }

  Future<void> _removerFuncionario(User funcionario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente remover ${funcionario.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _companyService.removeEmployee(
          funcionario.id!,
          widget.adminUserId,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${funcionario.name} removido com sucesso'),
            backgroundColor: Colors.green,
          ),
        );

        _carregarFuncionarios();
        widget.onFuncionarioRemovido?.call(); // Notifica o pai
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método público para recarregar (chamado pelo pai)
  void recarregar() {
    _carregarFuncionarios();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Funcionários Cadastrados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Chip(
                    label: Text('${_funcionarios.length}'),
                    backgroundColor: const Color(0xFF0857C3),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _carregarFuncionarios,
                    tooltip: 'Atualizar',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _funcionarios.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.person_off_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum funcionário cadastrado',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _funcionarios.length,
                      itemBuilder: (context, index) {
                        final funcionario = _funcionarios[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0857C3),
                              child: Text(
                                funcionario.name
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              funcionario.name ?? 'Sem nome',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(funcionario.email ?? 'Sem email'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color.fromARGB(255, 255, 145, 0)),
                                  onPressed: () =>
                                      _editarFuncionario(funcionario),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _removerFuncionario(funcionario),
                                  tooltip: 'Remover',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
