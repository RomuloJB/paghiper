import 'package:flutter/material.dart';
import 'package:flutter_application_1/Banco/entidades/Company.dart';
import 'package:flutter_application_1/Banco/entidades/User.dart';
import 'package:flutter_application_1/Services/CompanyService.dart';
import 'package:flutter_application_1/Banco/DAO/CompanyDAO.dart';
import 'package:flutter_application_1/banco/DAO/UserDAO.dart';
import 'package:flutter_application_1/Telas/funcionario/WidgetSignUser.dart';

/// Página principal de gerenciamento de funcionários
class WidgetUserPage extends StatefulWidget {
  final int adminUserId;

  const WidgetUserPage({
    Key? key,
    required this.adminUserId,
  }) : super(key: key);

  @override
  State<WidgetUserPage> createState() => _WidgetUserPageState();
}

class _WidgetUserPageState extends State<WidgetUserPage> {
  final _companyService = CompanyService();
  final _companyDAO = CompanyDao();
  final _userDao = UserDao();

  List<Company> _listCompanies = [];
  Company? _empresaSelecionada;
  List<User> _allFuncionarios = [];
  User? _selectedFuncionario;
  
  bool _isLoadingCompanies = true;
  bool _isLoadingFuncionarios = false;

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
      
      if (_empresaSelecionada != null) {
        _carregarFuncionarios();
      }
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

  Future<void> _carregarFuncionarios() async {
    if (_empresaSelecionada == null) return;
    
    setState(() => _isLoadingFuncionarios = true);
    try {
      final funcionarios = await _companyService.listEmployees(
        _empresaSelecionada!.id!,
        widget.adminUserId,
      );
      setState(() {
        _allFuncionarios = funcionarios;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar funcionários: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingFuncionarios = false);
    }
  }

  Future<void> _editarFuncionario(User funcionario) async {
    final nomeController = TextEditingController(text: funcionario.name);
    final emailController = TextEditingController(text: funcionario.email);
    final senhaController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Funcionário'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0857C3)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0857C3)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nova Senha (opcional)',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0857C3)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        if (nomeController.text.trim().isEmpty) {
          throw Exception('Nome não pode estar vazio');
        }
        if (emailController.text.trim().isEmpty) {
          throw Exception('E-mail não pode estar vazio');
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
          throw Exception('E-mail inválido');
        }

        final funcionarioAtualizado = funcionario.copyWith(
          name: nomeController.text.trim(),
          email: emailController.text.trim().toLowerCase(),
          password: senhaController.text.isNotEmpty ? senhaController.text : funcionario.password,
        );

        await _userDao.update(funcionarioAtualizado);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${funcionarioAtualizado.name} atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );

        _carregarFuncionarios();
        setState(() => _selectedFuncionario = funcionarioAtualizado);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

        setState(() => _selectedFuncionario = null);
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
  }

  Future<void> _navegarParaCadastro() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WidgetSignUser(
          adminUserId: widget.adminUserId,
        ),
      ),
    );

    // Se cadastrou um funcionário, recarregar a lista
    if (resultado == true) {
      _carregarFuncionarios();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Funcionários'),
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
                          'Cadastre uma empresa antes de gerenciar funcionários',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dropdown de seleção de empresa
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: DropdownButtonFormField<Company>(
                            value: _empresaSelecionada,
                            decoration: InputDecoration(
                              labelText: 'Selecione a Empresa',
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
                              setState(() {
                                _empresaSelecionada = company;
                                _selectedFuncionario = null;
                              });
                              _carregarFuncionarios();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botão adicionar funcionário
                      ElevatedButton.icon(
                        onPressed: _navegarParaCadastro,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Adicionar Funcionário'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24d17a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo de busca com dropdown integrado
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
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
                                      Icons.search,
                                      color: Color(0xFF0857C3),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Buscar Funcionário',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Dropdown com busca integrada
                              if (_isLoadingFuncionarios)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0857C3),
                                    ),
                                  ),
                                )
                              else if (_allFuncionarios.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.person_off_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Nenhum funcionário cadastrado',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Autocomplete<User>(
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _allFuncionarios;
                                    }
                                    final query = textEditingValue.text.toLowerCase();
                                    return _allFuncionarios.where((User funcionario) {
                                      final nomeMatch = funcionario.name?.toLowerCase().contains(query) ?? false;
                                      final idMatch = funcionario.id?.toString().contains(query) ?? false;
                                      return nomeMatch || idMatch;
                                    });
                                  },
                                  displayStringForOption: (User funcionario) =>
                                      '${funcionario.name} (ID: ${funcionario.id})',
                                  onSelected: (User funcionario) {
                                    setState(() => _selectedFuncionario = funcionario);
                                  },
                                  fieldViewBuilder: (
                                    BuildContext context,
                                    TextEditingController textEditingController,
                                    FocusNode focusNode,
                                    VoidCallback onFieldSubmitted,
                                  ) {
                                    return TextFormField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Buscar por nome ou ID',
                                        hintText: 'Digite para filtrar...',
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: Color(0xFF0857C3),
                                        ),
                                        suffixIcon: textEditingController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  textEditingController.clear();
                                                  setState(() => _selectedFuncionario = null);
                                                },
                                              )
                                            : const Icon(
                                                Icons.arrow_drop_down,
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
                                    );
                                  },
                                  optionsViewBuilder: (
                                    BuildContext context,
                                    AutocompleteOnSelected<User> onSelected,
                                    Iterable<User> options,
                                  ) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4.0,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          constraints: const BoxConstraints(maxHeight: 300),
                                          width: MediaQuery.of(context).size.width - 88,
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final User funcionario = options.elementAt(index);
                                              return InkWell(
                                                onTap: () => onSelected(funcionario),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey[200]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor: const Color(0xFF0857C3),
                                                        child: Text(
                                                          funcionario.name
                                                                  ?.substring(0, 1)
                                                                  .toUpperCase() ??
                                                              '?',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              funcionario.name ?? 'Sem nome',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.w500,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              'ID: ${funcionario.id}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Card com dados do funcionário selecionado
                      if (_selectedFuncionario != null)
                        Card(
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: const Color(0xFF0857C3),
                                      child: Text(
                                        _selectedFuncionario!.name
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFuncionario!.name ??
                                                'Sem nome',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF212121),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedFuncionario!.email ??
                                                'Sem email',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ID: ${_selectedFuncionario!.id}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFFFF9100),
                                        size: 28,
                                      ),
                                      onPressed: () => _editarFuncionario(_selectedFuncionario!),
                                      tooltip: 'Editar',
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                      onPressed: () => _removerFuncionario(_selectedFuncionario!),
                                      tooltip: 'Remover',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
