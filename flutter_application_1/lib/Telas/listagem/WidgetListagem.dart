import 'package:flutter/material.dart';
import 'package:flutter_application_1/Telas/listagem/ContractDeatil.dart';
import 'package:flutter_application_1/banco/DAO/ContractsDAO.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/Banco/entidades/Contract.dart';
import 'package:flutter_application_1/Banco/entidades/Partner.dart';
import 'package:flutter_application_1/Services/ContractService.dart';
import 'package:flutter_application_1/Banco/dao/PartnerDao.dart';

class WidgetListagem extends StatefulWidget {
  const WidgetListagem({Key? key}) : super(key: key);

  @override
  State<WidgetListagem> createState() => _WidgetListagemState();
}

class _WidgetListagemState extends State<WidgetListagem> {
  final ContractService _contractService = ContractService();
  final PartnerDao _partnerDao = PartnerDao();
  final ContractDao _contractDao = ContractDao();

  late Future<List<Contract>> _contractsFuture;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadContracts();
    _searchController.addListener(_onFilterChanged);
    _cnpjController.addListener(_onFilterChanged);
  }

  void _loadContracts() {
    _contractsFuture = _applyFilters();
  }

  Future<List<Contract>> _applyFilters() async {
    final nameFilter =
        _searchController.text.isNotEmpty ? _searchController.text : null;
    final cnpjFilter =
        _cnpjController.text.isNotEmpty ? _cnpjController.text : null;
    final statusFilter = _selectedStatus;

    final List<Contract> contracts = await _contractDao.findByFilters(
      name: nameFilter,
      cnpjFragment: cnpjFilter,
      status: statusFilter,
    );

    return contracts;
  }

  void _onFilterChanged() {
    setState(() {
      _loadContracts();
    });
  }

  Future<void> _deleteContract(String id) async {
    await _contractService.deleteContract(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contrato excluído com sucesso')),
    );
    setState(() => _loadContracts());
  }

  Future<List<Partner>> _getPartners(String contractId) async {
    return await _partnerDao.findByContract(contractId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 700 ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Contratos Analisados'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0857C3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔹 Filtros estilizados (card moderno)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Card(
              elevation: 6,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filtros de Pesquisa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0857C3),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buscar por nome
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar por nome da empresa',
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF0857C3)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF0857C3), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Buscar por CNPJ
                    TextField(
                      controller: _cnpjController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Buscar por CNPJ (parcial)',
                        prefixIcon:
                            const Icon(Icons.badge, color: Color(0xFF0857C3)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF0857C3), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _cnpjController.text.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _cnpjController.clear();
                                    _loadContracts();
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown de status
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      hint: const Text('Filtrar por status'),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.filter_list,
                            color: Color(0xFF0857C3)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF0857C3), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'processed',
                            child: Text('Análise Concluída')),
                        DropdownMenuItem(
                            value: 'processing',
                            child: Text('Em Processamento')),
                        DropdownMenuItem(
                            value: 'failed', child: Text('Falhou')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pendente')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                          _loadContracts();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Chips + botão limpar filtros
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_selectedStatus != null)
                                Chip(
                                  label: Text(
                                    _selectedStatus == 'processed'
                                        ? 'Análise Concluída'
                                        : _selectedStatus == 'processing'
                                            ? 'Em Processamento'
                                            : _selectedStatus == 'failed'
                                                ? 'Falhou'
                                                : 'Pendente',
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                  avatar: const Icon(
                                    Icons.info,
                                    size: 18,
                                    color: Color(0xFF0857C3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Botão de limpar filtros com ícone de vassoura
                        IconButton(
                          onPressed: (_selectedStatus != null ||
                                  _searchController.text.isNotEmpty ||
                                  _cnpjController.text.isNotEmpty)
                              ? () {
                                  setState(() {
                                    _selectedStatus = null;
                                    _searchController.clear();
                                    _cnpjController.clear();
                                    _loadContracts();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.cleaning_services),
                          color: Colors.red,
                          tooltip: 'Limpar filtros',
                          iconSize: 28,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 Lista de contratos
          Expanded(
            child: FutureBuilder<List<Contract>>(
              future: _contractsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum contrato encontrado.'));
                }

                final contracts = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    final bool isProcessed = contract.status == 'processed';
                    final Color statusColor =
                        isProcessed ? Colors.green : Colors.orange;
                    final String statusText =
                        isProcessed ? 'Análise Concluída' : 'Em Processamento';

                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: statusColor, size: 26),
                                const SizedBox(width: 8),
                                Text(
                                  statusText,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.visibility,
                                      color: Colors.blue),
                                  tooltip: 'Ver detalhes do contrato',
                                  onPressed: () async {
                                    final partners =
                                        await _getPartners(contract.id);
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ContractDetail(
                                            contract: contract,
                                            partners: partners),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteContract(contract.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (contract.companyName != null)
                              _infoTile(
                                icon: Icons.business,
                                color: Colors.blueAccent,
                                title: contract.companyName!,
                                subtitle: 'Razão Social',
                              ),
                            if (contract.cnpj != null)
                              _infoTile(
                                icon: Icons.badge,
                                color: Colors.orange,
                                title: contract.cnpj!,
                                subtitle: 'CNPJ',
                              ),
                            if (contract.capitalSocial != null)
                              _infoTile(
                                icon: Icons.attach_money,
                                color: Colors.green,
                                title: currencyFormatter
                                    .format(contract.capitalSocial),
                                subtitle: 'Capital Social',
                              ),
                            if (contract.foundationDate != null)
                              _infoTile(
                                icon: Icons.calendar_today,
                                color: Colors.purple,
                                title: contract.foundationDate!,
                                subtitle: 'Data de Fundação',
                              ),
                            if (contract.address != null)
                              _infoTile(
                                icon: Icons.location_on,
                                color: Colors.pinkAccent,
                                title: contract.address!,
                                subtitle: 'Endereço',
                              ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Sócios Identificados',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<List<Partner>>(
                              future: _getPartners(contract.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return const Text('Erro ao carregar sócios');
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Text('Nenhum sócio cadastrado',
                                      style: TextStyle(color: Colors.grey));
                                }

                                final partners = snapshot.data!;
                                return Column(
                                  children: partners
                                      .map(
                                        (p) => _infoTile(
                                          icon: Icons.person,
                                          color: Colors.purple,
                                          title: p.name ?? 'Nome não informado',
                                          subtitle: p.role ?? 'Cargo',
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
