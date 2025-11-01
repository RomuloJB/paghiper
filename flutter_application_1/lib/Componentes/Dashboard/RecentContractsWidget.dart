import 'package:flutter/material.dart';
import 'package:flutter_application_1/Banco/entidades/Contract.dart';
import 'package:intl/intl.dart';

class RecentContractsWidget extends StatelessWidget {
  final List<Contract> contracts;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const RecentContractsWidget({
    Key? key,
    required this.contracts,
    this.isLoading = false,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: Color(0xFF0857C3),
          ),
        ),
      );
    }

    if (contracts.isEmpty) {
      return _buildEmptyState();
    }

    final recentContracts = contracts.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0857C3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF0857C3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Contratos Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
            if (contracts.length > 10 && onViewAll != null)
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver Todos'),
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0857C3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Tabela responsiva
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return Card(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header da tabela
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0857C3).withOpacity(0.1),
                            const Color(0xFF0857C3).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isWide) ...[
                            const SizedBox(
                              width: 40,
                              child: Text(
                                '#',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF0857C3),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'EMPRESA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF0857C3),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isWide) ...[
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'CNPJ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF0857C3),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'DATA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF0857C3),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 90,
                            child: Text(
                              'STATUS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF0857C3),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Linhas da tabela
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentContracts.length,
                      itemBuilder: (context, index) {
                        final contract = recentContracts[index];
                        final isLast = index == recentContracts.length - 1;
                        return _buildContractRow(
                          contract,
                          index + 1,
                          isWide,
                          isLast,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContractRow(
    Contract contract,
    int index,
    bool isWide,
    bool isLast,
  ) {
    final dateFormat = DateFormat('dd/MM/yy');
    final timeFormat = DateFormat('HH:mm');
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (contract.status) {
      case 'processed':
        statusColor = const Color(0xFF24d17a);
        statusIcon = Icons.check_circle;
        statusLabel = 'Sucesso';
        break;
      case 'failed':
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        statusLabel = 'Erro';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusLabel = 'Pendente';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusLabel = 'N/A';
    }

    final uploadDate = DateTime.parse(contract.uploadedAt);

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : Colors.grey.shade200,
              width: 1,
            ),
          ),
          borderRadius: isLast
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                )
              : null,
        ),
        child: Row(
          children: [
            // Número
            if (isWide) ...[
              SizedBox(
                width: 40,
                child: Text(
                  '#$index',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // Empresa
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contract.companyName ?? contract.filename,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isWide && contract.cnpj != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatarCNPJ(contract.cnpj!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // CNPJ (apenas em telas largas)
            if (isWide) ...[
              Expanded(
                flex: 2,
                child: Text(
                  contract.cnpj != null ? _formatarCNPJ(contract.cnpj!) : '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Data
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(uploadDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    timeFormat.format(uploadDate),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Status
            SizedBox(
              width: 90,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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

  String _formatarCNPJ(String cnpj) {
    final numeros = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (numeros.length == 14) {
      return '${numeros.substring(0, 2)}.${numeros.substring(2, 5)}.${numeros.substring(5, 8)}/${numeros.substring(8, 12)}-${numeros.substring(12, 14)}';
    }
    return cnpj;
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum contrato encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Envie seu primeiro contrato para análise',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
