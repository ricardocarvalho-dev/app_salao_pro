import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class EditarSalaoPage extends StatefulWidget {
  final String salaoId;

  const EditarSalaoPage({required this.salaoId, super.key});

  @override
  State<EditarSalaoPage> createState() => _EditarSalaoPageState();
}

class _EditarSalaoPageState extends State<EditarSalaoPage> {
  final _formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final celularController = TextEditingController();
  final celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String modoAgendamento = 'por_profissional';
  bool carregando = false;
  bool acessoPermitido = false;
  bool carregandoPermissao = true;

  String? logoUrl;

  @override
  void initState() {
    super.initState();
    verificarPermissao();
  }

  Future<void> verificarPermissao() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final perfil = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    acessoPermitido = perfil?['role'] == 'dono';
    setState(() => carregandoPermissao = false);

    if (acessoPermitido) {
      carregarDados();
    }
  }

  Future<void> carregarDados() async {
    final response = await Supabase.instance.client
        .from('saloes')
        .select('nome, celular, modo_agendamento, logo_url')
        .eq('id', widget.salaoId)
        .single();

    setState(() {
      nomeController.text = response['nome'] ?? '';
      celularController.text = response['celular'] ?? '';
      modoAgendamento = response['modo_agendamento'] ?? 'por_profissional';
      logoUrl = response['logo_url'];
    });
  }

  Future<void> salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => carregando = true);

    try {
      await Supabase.instance.client
          .from('saloes')
          .update({
            'nome': nomeController.text.trim(),
            'celular': celularController.text.trim(),
            'modo_agendamento': modoAgendamento,
            'logo_url': logoUrl,
          })
          .eq('id', widget.salaoId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => carregando = false);
    }
  }

  Future<void> selecionarEUploadLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final fileName = 'logo_${widget.salaoId}.png';
    final bucket = 'logos_saloes';

    final response = await Supabase.instance.client.storage
        .from(bucket)
        .uploadBinary(fileName, bytes, fileOptions: FileOptions(upsert: true));

    if (response != null && response is String) {
      setState(() {
        logoUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo carregada com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar logo')),
      );
    }
  }

  Future<void> removerLogo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover logo'),
        content: const Text('Tem certeza que deseja remover a logo do salão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (logoUrl != null) {
      final bucket = 'logos_saloes';
      final fileName = 'logo_${widget.salaoId}.png';

      await Supabase.instance.client.storage.from(bucket).remove([fileName]);
      setState(() => logoUrl = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo removida com sucesso')),
      );
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    celularController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (carregandoPermissao) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!acessoPermitido) {
      return const Scaffold(
        body: Center(child: Text('Acesso negado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações do Salão')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    /// Logo do salão
                    Center(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          GestureDetector(
                            onTap: selecionarEUploadLogo,
                            child: logoUrl != null
                                ? Image.network(logoUrl!, height: 80)
                                : Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.camera_alt),
                                  ),
                          ),
                          if (logoUrl != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: InkWell(
                                onTap: removerLogo,
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Nome do salão
                    TextFormField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do salão',
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe um nome' : null,
                    ),
                    const SizedBox(height: 16),

                    /// Celular
                    TextFormField(
                      controller: celularController,
                      decoration: const InputDecoration(
                        labelText: 'Celular',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [celularMask],
                    ),
                    const SizedBox(height: 16),

                    /// Modo de agendamento
                    DropdownButtonFormField<String>(
                      value: modoAgendamento,
                      decoration: const InputDecoration(
                        labelText: 'Modo de Agendamento',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'por_profissional',
                            child: Text('Por Profissional')),
                        DropdownMenuItem(
                            value: 'por_servico',
                            child: Text('Por Serviço')),
                      ],
                      onChanged: (value) => setState(() {
                        modoAgendamento = value!;
                      }),
                    ),
                    const SizedBox(height: 24),

                    carregando
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: salvarAlteracoes,
                              child: const Text(
                                'Salvar alterações',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
}
