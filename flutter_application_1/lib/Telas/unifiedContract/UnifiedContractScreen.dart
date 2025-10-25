import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/componentes/cards/ContractResultCard.dart';
import 'package:flutter_application_1/componentes/cards/PdfPreviewCard.dart';
import 'package:flutter_application_1/componentes/dashboard/DashboardMetricsSection.dart';
import 'package:flutter_application_1/componentes/dashboard/ProcessingStepsWidget.dart';
import 'package:flutter_application_1/componentes/dashboard/RecentContractsWidget.dart';
import 'package:flutter_application_1/Routes/rotas.dart';
import 'package:flutter_application_1/Services/EnhancedContractService.dart';
import 'package:flutter_application_1/Banco/DAO/ContractsDAO.dart';
import 'package:flutter_application_1/Banco/entidades/Contract.dart';
import 'package:pdfx/pdfx.dart';

class UnifiedContractScreen extends StatefulWidget {
  const UnifiedContractScreen({Key? key}) : super(key: key);

  @override
  _UnifiedContractScreenState createState() => _UnifiedContractScreenState();
}

class _UnifiedContractScreenState extends State<UnifiedContractScreen> {
  final _contractService = EnhancedContractService();
  final _contractDao = ContractDao();
  final _contractNameController = TextEditingController();
  final _notesController = TextEditingController();

  PlatformFile? _selectedFile;
  Map<String, dynamic>? _processedData;
  bool _isUploading = false;
  PdfController? _pdfController;

  String _currentStep = 'upload';
  int _progress = 0;
  String? _protocolCode;

  int _totalContratos = 0;
  int _totalProcessados = 0;
  int _totalFalhas = 0;
  double _mediaCapitalSocial = 0;
  bool _isLoadingMetrics = true;

  List<Contract> _recentContracts = [];
  bool _isLoadingContracts = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _contractNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardMetrics() async {
    setState(() {
      _isLoadingMetrics = true;
      _isLoadingContracts = true;
    });

    try {
      final contracts = await _contractDao.readAll();

      _totalContratos = contracts.length;
      _totalProcessados =
          contracts.where((c) => c.status == 'processed').length;
      _totalFalhas = contracts.where((c) => c.status == 'failed').length;

      if (contracts.isNotEmpty) {
        final sumCapital = contracts
            .where((c) => c.capitalSocial != null)
            .fold<double>(0, (sum, c) => sum + c.capitalSocial!);
        _mediaCapitalSocial = sumCapital / contracts.length;
      }

      _recentContracts = contracts;
    } catch (e) {
      debugPrint('Erro ao carregar métricas: $e');
    } finally {
      setState(() {
        _isLoadingMetrics = false;
        _isLoadingContracts = false;
      });
    }
  }

  void _resetUploadForm() {
    setState(() {
      _pdfController?.dispose();
      _pdfController = null;
      _selectedFile = null;
      _processedData = null;
      _contractNameController.clear();
      _notesController.clear();
    });
  }

  Future<void> _pickFile() async {
    _resetUploadForm();
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Confirmar Envio"),
        content: Text(
          "Você realmente deseja enviar o contrato ${_selectedFile!.name} para análise?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.red),
            ),
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
      _isUploading = true;
      _processedData = null;
      _currentStep = 'upload';
      _progress = 0;
      _protocolCode = null;
    });

    try {
      final result =
          await _contractService.uploadAndProcessContractWithProtocol(
        file: _selectedFile!,
        customName: _contractNameController.text.isNotEmpty
            ? _contractNameController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        onProgress: (step, progress, protocolCode) {
          setState(() {
            _currentStep = step;
            _progress = progress;
            _protocolCode = protocolCode;
          });
        },
      );

      setState(() {
        _processedData = result;
        _pdfController?.dispose();
        _pdfController = null;
      });

      _showSnack('Contrato processado e salvo com sucesso!', Colors.green);

      _loadDashboardMetrics();
    } catch (e) {
      _showSnack(
        'Erro: ${e.toString().replaceAll("Exception: ", "")}',
        Colors.red,
      );
    } finally {
      setState(() => _isUploading = false);
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Análise de Contratos"),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0857C3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add_business),
            tooltip: 'Cadastrar empresa',
            onPressed: () => Navigator.pushNamed(context, Rotas.signNewCompany),
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Cadastrar funcionário',
            onPressed: () => Navigator.pushNamed(context, Rotas.signNewUser),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Consultar Protocolo',
            onPressed: () => Navigator.pushNamed(context, Rotas.protocolSearch),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Ver Listagem Completa',
            onPressed: () => Navigator.pushNamed(context, Rotas.listagem),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadDashboardMetrics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== SEÇÃO 1: NOVO CONTRATO (PRIORITÁRIA) =====
                  if (_processedData == null) ...[
                    const Text(
                      'Novo Contrato',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, size: 22),
                      label: const Text('Selecionar PDF'),
                      onPressed: _isUploading ? null : _pickFile,
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
                    if (_pdfController != null && _selectedFile != null) ...[
                      PdfPreviewCard(
                        file: _selectedFile!,
                        pdfController: _pdfController!,
                      ),
                      const SizedBox(height: 24),
                    ],
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
                        enabled: !_isUploading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Observações (Opcional)',
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
                        maxLines: 3,
                        enabled: !_isUploading,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: (_selectedFile == null || _isUploading)
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
                        child: const Text(
                          'Enviar Contrato para Análise',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],

                  if (_processedData != null) ...[
                    ContractResultCard(
                      data: _processedData!,
                      onAnalyzeAnother: _resetUploadForm,
                      onGoToDashboard: () {
                        Navigator.pushNamed(context, Rotas.dashboard);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ===== SEÇÃO 2: VISÃO GERAL (MÉTRICAS) =====
                  const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 24),

                  DashboardMetricsSection(
                    totalContratos: _totalContratos,
                    totalProcessados: _totalProcessados,
                    totalFalhas: _totalFalhas,
                    mediaCapitalSocial: _mediaCapitalSocial,
                    isLoading: _isLoadingMetrics,
                  ),

                  const SizedBox(height: 32),
                  const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 24),

                  // ===== SEÇÃO 3: CONTRATOS RECENTES =====
                  RecentContractsWidget(
                    contracts: _recentContracts,
                    isLoading: _isLoadingContracts,
                    onViewAll: () =>
                        Navigator.pushNamed(context, Rotas.listagem),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(220, 0, 0, 0),
                child: Center(
                  child: ProcessingStepsWidget(
                    currentStep: _currentStep,
                    progress: _progress,
                    protocolCode: _protocolCode,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
