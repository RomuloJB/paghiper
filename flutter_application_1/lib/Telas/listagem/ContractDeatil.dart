import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/Banco/entidades/Contract.dart';
import 'package:flutter_application_1/Banco/entidades/Partner.dart';

class ContractDetail extends StatelessWidget {
  final Contract contract;
  final List<Partner> partners;

  const ContractDetail({
    Key? key,
    required this.contract,
    required this.partners,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = 16.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(contract.companyName ?? 'Detalhes do Contrato'),
        backgroundColor: const Color(0xFF0857C3),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        children: [
          // === CARD: Dados da Empresa ===
          _buildSectionCard(
            title: 'Dados da Empresa',
            icon: Icons.business,
            color: Colors.blueAccent,
            children: [
              if (contract.companyName != null)
                _infoTile(
                    icon: Icons.business,
                    color: Colors.blueAccent,
                    title: contract.companyName!,
                    subtitle: 'Razão Social'),
              if (contract.cnpj != null)
                _infoTile(
                    icon: Icons.badge,
                    color: Colors.orange,
                    title: contract.cnpj!,
                    subtitle: 'CNPJ'),
              if (contract.address != null)
                _infoTile(
                    icon: Icons.location_on,
                    color: Colors.pinkAccent,
                    title: contract.address!,
                    subtitle: 'Endereço'),
              if (contract.foundationDate != null)
                _infoTile(
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                    title: contract.foundationDate!,
                    subtitle: 'Data de Fundação'),
              if (contract.capitalSocial != null)
                _infoTile(
                  icon: Icons.attach_money,
                  color: Colors.green,
                  title: currencyFormatter.format(contract.capitalSocial),
                  subtitle: 'Capital Social',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // === CARD: Metadados ===
          _buildSectionCard(
            title: 'Metadados',
            icon: Icons.info_outline,
            color: Colors.teal,
            children: [
              _infoTile(
                  icon: Icons.description,
                  color: Colors.grey[700]!,
                  title: contract.filename,
                  subtitle: 'Arquivo'),
              _infoTile(
                icon: Icons.sync,
                color: contract.status == 'processed'
                    ? Colors.green
                    : Colors.orange,
                title: _getStatusText(contract.status),
                subtitle: 'Status',
              ),
              if (contract.uploadedAt.isNotEmpty)
                _infoTile(
                    icon: Icons.upload_file,
                    color: Colors.indigo,
                    title: contract.uploadedAt,
                    subtitle: 'Enviado em'),
              if (contract.processedAt != null)
                _infoTile(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    title: contract.processedAt!,
                    subtitle: 'Processado em'),
              if (contract.confidence != null)
                _infoTile(
                  icon: Icons.bar_chart,
                  color: Colors.cyan,
                  title: '${(contract.confidence! * 100).toStringAsFixed(1)}%',
                  subtitle: 'Confiança da Análise',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // === CARD: Observações (SEM JSON BRUTO) ===
          _buildSectionCard(
            title: 'Observações',
            icon: Icons.edit,
            color: Colors.orange,
            children: [
              if (contract.notes != null && contract.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    contract.notes!,
                    style: const TextStyle(
                        fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                )
              else
                const Text(
                  'Nenhuma observação disponível',
                  style: TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // === CARD: Sócios ===
          _buildSectionCard(
            title: 'Sócios Identificados',
            icon: Icons.people,
            color: Colors.purple,
            children: [
              if (partners.isEmpty)
                const Text(
                  'Nenhum sócio cadastrado',
                  style: TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic),
                )
              else
                ...partners.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoTile(
                            icon: Icons.person,
                            color: Colors.purple,
                            title: p.name ?? 'Nome não informado',
                            subtitle: p.role ?? 'Cargo não especificado',
                          ),
                          if (p.cpfCnpj != null || p.quotaPercent != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 34, top: 4),
                              child: Row(
                                children: [
                                  if (p.cpfCnpj != null)
                                    _tagChip(
                                        label: p.cpfCnpj!,
                                        icon: Icons.badge,
                                        color: Colors.orange.shade100),
                                  const SizedBox(width: 8),
                                  if (p.quotaPercent != null)
                                    _tagChip(
                                      label: '${p.quotaPercent!.toString()}%',
                                      icon: Icons.pie_chart,
                                      color: Colors.green.shade100,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )),
            ],
          ),
        ],
      ),
    );
  }

  // === WIDGETS AUXILIARES ===

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 20, thickness: 0.8),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(
      {required String label, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'processed':
        return 'Análise Concluída';
      case 'processing':
        return 'Em Processamento';
      case 'failed':
        return 'Falhou';
      case 'pending':
        return 'Pendente';
      default:
        return status ?? 'Desconhecido';
    }
  }
}
