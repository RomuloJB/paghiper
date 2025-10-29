// lib/screens/new_contract_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Routes/rotas.dart';
import 'package:flutter_application_1/Services/ContractService.dart';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart';

class NewContractScreen extends StatefulWidget {
  const NewContractScreen({Key? key}) : super(key: key);

  @override
  _NewContractScreenState createState() => _NewContractScreenState();
}

class _NewContractScreenState extends State<NewContractScreen> {
  final _contractService = ContractService();
  final _contractNameController = TextEditingController();
  final _notesController = TextEditingController();

  PlatformFile? _selectedFile;
  Map<String, dynamic>? _processedData;
  bool _isLoading = false;
  String? _statusMessage;
  Color _messageColor = Colors.black;
  PdfController? _pdfController;

  @override
  void dispose() {
    _pdfController?.dispose();
    _contractNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetScreen() {
    setState(() {
      _pdfController?.dispose();
      _pdfController = null;
      _selectedFile = null;
      _processedData = null;
      _statusMessage = null;
      _isLoading = false;
      _contractNameController.clear();
      _notesController.clear();
    });
  }

  Future<void> _pickFile() async {
    _resetScreen();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      final file = result.files.first;
      setState(() {
        _selectedFile = file;
        _pdfController = PdfController(
          document: PdfDocument.openData(file.bytes!),
        );
      });
    } else {
      _showSnack("Não foi possível carregar o arquivo PDF.", Colors.red);
    }
  }

  Future<void> _confirmAndUpload() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: const Text("Confirmar Envio"),
        content: Text(
          "Você realmente deseja enviar o contrato ${_selectedFile!.name} para análise?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF24d17a),
              foregroundColor: Colors.white,
            ),
            child: const Text("Enviar"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _uploadAndProcess();
    }
  }

  Future<void> _uploadAndProcess() async {
    if (_selectedFile == null) return;

    final validationError = _contractService.validateFile(_selectedFile!);
    if (validationError != null) {
      _showSnack(validationError, Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando e processando...';
      _messageColor = Colors.blue;
      _processedData = null;
    });

    try {
      final result = await _contractService.uploadAndProcessContract(
        file: _selectedFile!,
        customName: _contractNameController.text.isNotEmpty
            ? _contractNameController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      setState(() {
        _statusMessage = 'Contrato processado e salvo com sucesso!';
        _messageColor = Colors.green;
        _processedData = result;
        _pdfController?.dispose();
        _pdfController = null;
      });
      _showSnack(_statusMessage!, Colors.green);
    } catch (e) {
      _showSnack(
        'Erro: ${e.toString().replaceAll("Exception: ", "")}',
        Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Submeter novo contrato"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF0857C3),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_processedData == null) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 22),
                    label: const Text('Selecionar PDF'),
                    onPressed: _isLoading ? null : _pickFile,
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
                  if (_pdfController != null) _buildPdfPreview(),
                  const SizedBox(height: 24),
                  if (_selectedFile != null) ...[
                    TextField(
                      controller: _contractNameController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Contrato (Opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0857C3),
                            width: 2,
                          ),
                        ),
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF0857C3),
                        ),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Observações (Opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0857C3),
                            width: 2,
                          ),
                        ),
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF0857C3),
                        ),
                      ),
                      maxLines: 3,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_selectedFile == null || _isLoading)
                          ? null
                          : _confirmAndUpload,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF24d17a),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Enviar Contrato'),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                if (_processedData != null) _buildResultsCard(_processedData!),
              ],
            ),
          ),

          // Overlay durante o carregamento
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(206, 0, 0, 0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        "Enviando contrato para análise...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Column(
      children: [
        Text(
          _selectedFile!.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 420,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            surfaceTintColor: const Color(0xFF24d17a),
            child: PdfView(controller: _pdfController!),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCard(Map<String, dynamic> data) {
    final partners = (data['partners'] as List?) ?? <dynamic>[];
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Column(
      children: [
        Card(
          elevation: 3,
          color: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resultados da Análise',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.blueAccent),
                  title: Text(data['company_name'] ?? 'Não informado'),
                  subtitle:
                      Text(data['filename'] ?? (_selectedFile?.name ?? '')),
                ),
                ListTile(
                  leading: const Icon(Icons.pin, color: Colors.orangeAccent),
                  title: Text(data['cnpj'] ?? 'Não informado'),
                  subtitle: const Text('CNPJ'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.attach_money,
                    color: Colors.greenAccent,
                  ),
                  title: Text(
                    currencyFormatter.format(data['capital_social'] ?? 0),
                  ),
                  subtitle: const Text('Capital Social'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sócios Encontrados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (partners.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhum sócio identificado',
                        style: TextStyle(color: Colors.grey)),
                  ),

                // Detalhes por sócio
                ...partners.map((p) {
                  final Map<String, dynamic> partner = (p is Map)
                      ? Map<String, dynamic>.from(p)
                      : {'name': p.toString()};

                  final name = partner['name'] ??
                      partner['nome'] ??
                      partner['full_name'] ??
                      'Nome não informado';

                  final role = partner['role'] ??
                      partner['cargo'] ??
                      partner['qualification'] ??
                      partner['position'] ??
                      null;

                  final cpfCnpj = partner['cpf_cnpj'] ??
                      partner['cpfCnpj'] ??
                      partner['cpf'] ??
                      partner['cnpj'] ??
                      null;

                  final quotaRaw = partner['quota_percent'] ??
                      partner['quotaPercent'] ??
                      partner['quota'] ??
                      null;
                  String? quota;
                  if (quotaRaw != null) {
                    if (quotaRaw is num) {
                      quota = '${quotaRaw.toString()}%';
                    } else {
                      quota = quotaRaw.toString();
                    }
                  }

                  final capitalSubscribedRaw = partner['capital_subscribed'] ??
                      partner['capitalSubscribed'] ??
                      null;
                  String? capitalSubscribed;
                  if (capitalSubscribedRaw != null) {
                    try {
                      final numVal = (capitalSubscribedRaw is num)
                          ? capitalSubscribedRaw
                          : num.parse(capitalSubscribedRaw.toString());
                      capitalSubscribed = currencyFormatter.format(numVal);
                    } catch (_) {
                      capitalSubscribed = capitalSubscribedRaw.toString();
                    }
                  }

                  final address = partner['address'] ??
                      partner['endereco'] ??
                      partner['location'] ??
                      null;

                  return Padding(
                    key: ValueKey(name + (cpfCnpj ?? '')),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          if (role != null)
                            Text('Cargo: $role',
                                style: const TextStyle(color: Colors.grey)),
                          if (cpfCnpj != null)
                            Text('CPF/CNPJ: $cpfCnpj',
                                style: const TextStyle(color: Colors.grey)),
                          if (quota != null)
                            Text('Quota: $quota',
                                style: const TextStyle(color: Colors.grey)),
                          if (capitalSubscribed != null)
                            Text('Capital Subscrito: $capitalSubscribed',
                                style: const TextStyle(color: Colors.grey)),
                          if (address != null)
                            Text('Endereço: $address',
                                style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Wrap(
            spacing: 6,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Analisar Outro Contrato'),
                onPressed: _resetScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0857C3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Ir para Dashboard'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(Rotas.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24d17a),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
