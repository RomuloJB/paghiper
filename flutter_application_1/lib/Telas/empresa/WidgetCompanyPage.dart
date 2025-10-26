import 'package:flutter/material.dart';
import 'package:flutter_application_1/Banco/entidades/Company.dart';
import 'package:flutter_application_1/Banco/DAO/CompanyDAO.dart';
import 'package:flutter_application_1/Telas/empresa/WidgetSignCompany.dart';

/// Página principal de gerenciamento de empresas
class WidgetCompanyPage extends StatefulWidget {
  const WidgetCompanyPage({
    Key? key,
  }) : super(key: key);

  @override
  State<WidgetCompanyPage> createState() => _WidgetCompanyPageState();
}

class _WidgetCompanyPageState extends State<WidgetCompanyPage> {
  final _companyDAO = CompanyDao();

  List<Company> _allCompanies = [];
  Company? _selectedCompany;
  
  bool _isLoadingCompanies = true;

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
        _allCompanies = companies;
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

  Future<void> _editarEmpresa(Company empresa) async {
    final nomeController = TextEditingController(text: empresa.name);
    final cnpjController = TextEditingController(text: empresa.cnpj ?? '');

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Empresa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Empresa',
                  prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFF0857C3)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: cnpjController,
                decoration: InputDecoration(
                  labelText: 'CNPJ (opcional)',
                  prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0857C3)),
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
          throw Exception('Nome da empresa não pode estar vazio');
        }

        final empresaAtualizada = empresa.copyWith(
          name: nomeController.text.trim(),
          cnpj: cnpjController.text.trim().isNotEmpty ? cnpjController.text.trim() : null,
        );

        await _companyDAO.update(empresaAtualizada);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${empresaAtualizada.name} atualizada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );

        _carregarEmpresas();
        setState(() => _selectedCompany = empresaAtualizada);
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
    cnpjController.dispose();
  }

  Future<void> _removerEmpresa(Company empresa) async {
    // Verificar se tem funcionários vinculados
    try {
      final numFuncionarios = await _companyDAO.countEmployees(empresa.id!);
      
      if (numFuncionarios > 0) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Não é possível remover'),
            content: Text(
              'A empresa "${empresa.name}" possui $numFuncionarios funcionário(s) vinculado(s). '
              'Remova todos os funcionários antes de excluir a empresa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao verificar funcionários: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente remover a empresa "${empresa.name}"?'),
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
        await _companyDAO.delete(empresa.id!);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empresa "${empresa.name}" removida com sucesso'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() => _selectedCompany = null);
        _carregarEmpresas();
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
        builder: (context) => const WidgetSignCompany(),
      ),
    );

    // Se cadastrou uma empresa, recarregar a lista
    if (resultado == true) {
      _carregarEmpresas();
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
        title: const Text('Empresas'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botão adicionar empresa
                  ElevatedButton.icon(
                    onPressed: _navegarParaCadastro,
                    icon: const Icon(Icons.add_business),
                    label: const Text('Adicionar Empresa'),
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
                                  color: const Color(0xFF0857C3).withOpacity(0.1),
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
                                'Buscar Empresa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Dropdown com busca integrada
                          if (_isLoadingCompanies)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0857C3),
                                ),
                              ),
                            )
                          else if (_allCompanies.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'Nenhuma empresa cadastrada',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          else
                            Autocomplete<Company>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _allCompanies;
                                }
                                final query = textEditingValue.text.toLowerCase();
                                return _allCompanies.where((empresa) {
                                  final nomeMatch = empresa.name.toLowerCase().contains(query);
                                  final idMatch = empresa.id.toString().contains(query);
                                  final cnpjMatch = empresa.cnpj?.contains(query) ?? false;
                                  return nomeMatch || idMatch || cnpjMatch;
                                });
                              },
                              displayStringForOption: (Company empresa) =>
                                  '${empresa.name} (ID: ${empresa.id})',
                              onSelected: (Company empresa) {
                                setState(() {
                                  _selectedCompany = empresa;
                                });
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
                                    labelText: 'Digite o nome, ID ou CNPJ da empresa',
                                    prefixIcon: const Icon(
                                      Icons.business_outlined,
                                      color: Color(0xFF0857C3),
                                    ),
                                    suffixIcon: textEditingController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              textEditingController.clear();
                                              setState(() {
                                                _selectedCompany = null;
                                              });
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
                                AutocompleteOnSelected<Company> onSelected,
                                Iterable<Company> options,
                              ) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(12),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 300,
                                        maxWidth: 400,
                                      ),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final empresa = options.elementAt(index);
                                          return InkWell(
                                            onTap: () => onSelected(empresa),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 12,
                                                horizontal: 16,
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
                                                    backgroundColor: const Color(0xFF0857C3),
                                                    radius: 20,
                                                    child: Text(
                                                      empresa.name.substring(0, 1).toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          empresa.name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        Text(
                                                          'ID: ${empresa.id}${empresa.cnpj != null ? ' • CNPJ: ${empresa.cnpj}' : ''}',
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

                  // Card com dados da empresa selecionada
                  if (_selectedCompany != null)
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
                                  backgroundColor: const Color(0xFF0857C3),
                                  radius: 30,
                                  child: Text(
                                    _selectedCompany!.name.substring(0, 1).toUpperCase(),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedCompany!.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF212121),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${_selectedCompany!.id}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color.fromARGB(255, 255, 145, 0),
                                  ),
                                  onPressed: () => _editarEmpresa(_selectedCompany!),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removerEmpresa(_selectedCompany!),
                                  tooltip: 'Remover',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            
                            // Informações detalhadas
                            _buildInfoRow(
                              Icons.badge_outlined,
                              'CNPJ',
                              _selectedCompany!.cnpj ?? 'Não informado',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Criada em',
                              _selectedCompany!.createdAt,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0857C3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
