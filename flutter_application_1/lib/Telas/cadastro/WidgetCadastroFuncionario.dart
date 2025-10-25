import 'package:flutter/material.dart';
import 'package:flutter_application_1/Banco/entidades/Company.dart';
import 'package:flutter_application_1/Services/CompanyService.dart';
import 'package:flutter_application_1/Banco/DAO/CompanyDAO.dart';
import 'package:flutter_application_1/Telas/cadastro/WidgetListaFuncionarios.dart';

/// Tela para admin adicionar funcionário vinculado a uma empresa
class WidgetCadastroFuncionario extends StatefulWidget {
  final int adminUserId;

  const WidgetCadastroFuncionario({
    Key? key,
    required this.adminUserId,
  }) : super(key: key);

  @override
  State<WidgetCadastroFuncionario> createState() =>
      _WidgetCadastroFuncionarioState();
}

class _WidgetCadastroFuncionarioState extends State<WidgetCadastroFuncionario> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _companyService = CompanyService();
  final _companyDAO = CompanyDao();

  // Key para controlar o widget filho
  final _listaKey = GlobalKey();

  List<Company> _listCompanies = [];
  Company? _empresaSelecionada;
  bool _isLoading = false;
  bool _isLoadingCompanies = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() => _isLoadingCompanies = true);
    try {
      final companies = await _companyDAO.readAll();
      setState(() {
        _listCompanies = companies;
        if (companies.isNotEmpty) {
          _empresaSelecionada = companies.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar empresas: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingCompanies = false);
    }
  }

  Future<void> _cadastrarFuncionario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_empresaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma empresa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final novoFuncionario = await _companyService.addEmployee(
        companyId: _empresaSelecionada!.id!,
        name: _nomeController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _senhaController.text,
        requestingUserId: widget.adminUserId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Funcionário ${novoFuncionario.name} adicionado à ${_empresaSelecionada!.name}!'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpar campos
      _nomeController.clear();
      _emailController.clear();
      _senhaController.clear();

      // Atualizar lista filha
      (_listaKey.currentState as dynamic)?.recarregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Gerenciar Funcionários'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0857C3),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingCompanies
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0857C3),
              ),
            )
          : _listCompanies.isEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0857C3).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: Color(0xFF0857C3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Nenhuma empresa cadastrada',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cadastre uma empresa antes de adicionar funcionários',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.add_business),
                          label: const Text('Cadastrar Empresa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF24d17a),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ========== FORMULÁRIO ==========
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0857C3)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.person_add,
                                        color: Color(0xFF0857C3),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Adicionar Funcionário',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Dropdown de empresas
                                DropdownButtonFormField<Company>(
                                  value: _empresaSelecionada,
                                  decoration: InputDecoration(
                                    labelText: 'Empresa',
                                    prefixIcon: const Icon(
                                      Icons.business,
                                      color: Color(0xFF0857C3),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0857C3),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: _listCompanies.map((company) {
                                    return DropdownMenuItem<Company>(
                                      value: company,
                                      child: Text(company.name),
                                    );
                                  }).toList(),
                                  onChanged: (company) {
                                    setState(() => _empresaSelecionada = company);
                                  },
                                  validator: (value) => value == null
                                      ? 'Selecione uma empresa'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _nomeController,
                                  decoration: InputDecoration(
                                    labelText: 'Nome do funcionário',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF0857C3),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0857C3),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe o nome';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'E-mail',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF0857C3),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0857C3),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe o e-mail';
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                        .hasMatch(value)) {
                                      return 'E-mail inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _senhaController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Senha inicial',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF0857C3),
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Mostrar senha'
                                          : 'Ocultar senha',
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0857C3),
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    helperText:
                                        'O funcionário poderá alterar depois',
                                    helperStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Informe a senha';
                                    }
                                    if (value.length < 6) {
                                      return 'Mínimo 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 28),

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF24d17a),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: const Color(0xFF24d17a)
                                          .withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _cadastrarFuncionario,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            'Adicionar Funcionário',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // LISTA DE FUNCIONÁRIOS
                      if (_empresaSelecionada != null)
                        WidgetListaFuncionarios(
                          key: _listaKey,
                          companyId: _empresaSelecionada!.id!,
                          adminUserId: widget.adminUserId,
                        ),
                    ],
                  ),
                ),
    );
  }
}
