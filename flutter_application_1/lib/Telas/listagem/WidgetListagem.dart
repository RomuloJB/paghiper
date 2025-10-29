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
  String? _selectedPartnerCount;
  String? _selectedStatus;
  String? _selectedSort;

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
    final partnerCountFilter = _selectedPartnerCount;
    final sortFilter = _selectedSort;

    final List<Contract> contracts = await _contractDao.findByFilters(
      name: nameFilter,
      cnpjFragment: cnpjFilter,
      status: statusFilter,
      partnerCount: partnerCountFilter,
      orderBy: sortFilter,
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

  // Widget pequeno: se onTap for fornecido, é interativo (InkWell); se null, é apenas um container
  Widget _smallSquare({
    required Widget child,
    VoidCallback? onTap,
    Color? color,
    bool selected = false,
  }) {
    final box = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color ??
            (selected
                ? const Color(0xFF0857C3)
                : Colors.white), // azul quando selecionado
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(child: child),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: box,
      );
    } else {
      // sem GestureDetector/InkWell para não bloquear o PopupMenuButton
      return box;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final horizontalPadding = 16.0;

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
          // Filtros estilizados seguindo padrão da tela
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1) Input de nome (sozinho, full width)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por nome da empresa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // 2) Linha: CNPJ (maior) + filtro de sócios (pequeno quadrado com ícone)
                Row(
                  children: [
                    // CNPJ input ocupa o restante
                    Expanded(
                      child: TextField(
                        controller: _cnpjController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Buscar por CNPJ (parcial)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.badge),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: _cnpjController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.red),
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
                    ),

                    const SizedBox(width: 12),

                    // PopupMenuButton child NÃO pode capturar o toque; por isso passamos um container (sem onTap)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _selectedPartnerCount =
                              value == 'clear' ? null : value;
                          _loadContracts();
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: '1', child: Text('1 sócio')),
                        const PopupMenuItem(
                            value: '2', child: Text('2 sócios')),
                        const PopupMenuItem(
                            value: '3+', child: Text('3 ou mais sócios')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                            value: 'clear',
                            child: Text('Limpar filtro de sócios')),
                      ],
                      child: _smallSquare(
                        // aqui não passamos onTap para não bloquear o PopupMenuButton
                        child: Icon(
                          Icons.people,
                          color: _selectedPartnerCount != null
                              ? Colors.white
                              : Colors.black87,
                        ),
                        selected: _selectedPartnerCount != null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3) Linha: filtro por status (maior) + ordenação pequena ao lado (A-Z)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        hint: const Text('Filtrar por status'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                    ),

                    const SizedBox(width: 12),

                    // Pequeno botão A-Z para ordenar alfabeticamente (interativo)
                    _smallSquare(
                      onTap: () {
                        setState(() {
                          // Toggle alphabetical sort
                          if (_selectedSort == 'alphabetical') {
                            _selectedSort = null;
                          } else {
                            _selectedSort = 'alphabetical';
                          }
                          _loadContracts();
                        });
                      },
                      child: Text(
                        'A-Z',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedSort == 'alphabetical'
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      selected: _selectedSort == 'alphabetical',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Linha de chips/indicadores de filtros ativos e botão "Limpar filtros" vermelho
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_selectedPartnerCount != null)
                            Chip(
                              label: Text(
                                  '${_selectedPartnerCount == '3+' ? '3+ sócios' : '${_selectedPartnerCount} sócio(s)'}'),
                              backgroundColor: Colors.blue.shade50,
                              avatar: const Icon(Icons.people,
                                  size: 18, color: Colors.blueAccent),
                            ),
                          if (_selectedStatus != null)
                            Chip(
                              label: Text(_selectedStatus == 'processed'
                                  ? 'Análise Concluída'
                                  : _selectedStatus ?? ''),
                              backgroundColor: Colors.orange.shade50,
                              avatar: const Icon(Icons.info,
                                  size: 18, color: Colors.orange),
                            ),
                          if (_selectedSort != null)
                            Chip(
                              label: const Text('A-Z'),
                              backgroundColor: Colors.green.shade50,
                              avatar: const Icon(Icons.sort_by_alpha,
                                  size: 18, color: Colors.green),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Botão vermelho para limpar todos os filtros
                    ElevatedButton.icon(
                      onPressed: (_selectedPartnerCount != null ||
                              _selectedStatus != null ||
                              _selectedSort != null)
                          ? () {
                              setState(() {
                                _selectedPartnerCount = null;
                                _selectedStatus = null;
                                _selectedSort = null;
                                _cnpjController.clear();
                                _searchController.clear();
                                _loadContracts();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpar filtros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de contratos
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
                            // cabeçalho de status
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
                                // Botão para visualizar detalhes completos
                                IconButton(
                                  icon: const Icon(Icons.visibility,
                                      color: Colors.blue),
                                  tooltip: 'Ver detalhes do contrato',
                                  onPressed: () async {
                                    // carrega sócios e navega para a tela de detalhes
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

                            // campos principais
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

                            // sócios
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
