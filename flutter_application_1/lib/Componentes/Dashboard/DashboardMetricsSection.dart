import 'package:flutter/material.dart';
import 'package:flutter_application_1/Componentes/Cards/MetricCard.dart';

class DashboardMetricsSection extends StatelessWidget {
  final int totalContratos;
  final int totalProcessados;
  final int totalFalhas;
  final int totalPendentes;
  final double mediaCapitalSocial;
  final bool isLoading;

  const DashboardMetricsSection({
    Key? key,
    required this.totalContratos,
    required this.totalProcessados,
    required this.totalPendentes,
    required this.totalFalhas,
    required this.mediaCapitalSocial,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visão Geral - Total de Contratos: ${totalContratos.toString()}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            MetricCard(
              label: "Processados",
              value: totalProcessados.toString(),
              color: const Color(0xFF24d17a),
              icon: Icons.check_circle,
            ),
            MetricCard(
              label: "Falhas",
              value: totalFalhas.toString(),
              color: Colors.redAccent,
              icon: Icons.error,
            ),
            MetricCard(
              label: "Pendentes",
              value: totalPendentes.toString(),
              color: Colors.orangeAccent,
              icon: Icons.hourglass_top,
            ),
          ],
        ),
      ],
    );
  }
}
