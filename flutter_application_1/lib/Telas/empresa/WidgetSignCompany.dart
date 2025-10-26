import 'package:flutter/material.dart';
import 'package:flutter_application_1/Services/CompanyService.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Tela para admin cadastrar sua empresa
class WidgetSignCompany extends StatefulWidget {
  const WidgetSignCompany({
    Key? key,
  }) : super(key: key);

  @override
  State<WidgetSignCompany> createState() => _WidgetSignCompanyState();
}

class _WidgetSignCompanyState extends State<WidgetSignCompany> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _companyService = CompanyService();
  bool _isLoading = false;

  // Máscara para CNPJ: 00.000.000/0000-00
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> _cadastrarEmpresa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final company = await _companyService.createCompany(
        name: _nomeController.text.trim(),
        cnpj: _cnpjController.text
            .replaceAll(RegExp(r'[^\d]'), ''), // Remove máscara
        adminUserId: 1, // TODO: Obter do usuário logado
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Empresa "${company.name}" cadastrada com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),    
        ),
      );

      // Limpar campos
      _nomeController.clear();
      _cnpjController.clear();
      
      // Retornar true para indicar sucesso (para quando for usado como página de navegação)
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Gerenciar Empresas'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0857C3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
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
                          color: const Color(0xFF0857C3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Color(0xFF0857C3),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Adicionar Empresa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome da Empresa',
                      prefixIcon: const Icon(
                        Icons.business_outlined,
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
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Informe o nome da empresa'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cnpjMask],
                    decoration: InputDecoration(
                      labelText: 'CNPJ (opcional)',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
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
                      hintText: '00.000.000/0000-00',
                      helperText: 'Formato: 00.000.000/0000-00',
                      helperStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final cnpjDigits = value.replaceAll(RegExp(r'[^\d]'), '');
                        if (cnpjDigits.length != 14) {
                          return 'CNPJ deve ter 14 dígitos';
                        }
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
                        shadowColor: const Color(0xFF24d17a).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _cadastrarEmpresa,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Cadastrar Empresa',
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
      ),
    );
  }
}
