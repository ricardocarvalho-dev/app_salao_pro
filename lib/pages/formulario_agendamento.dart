import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormularioAgendamento extends StatefulWidget {
  final String salaoId;
  final String modoAgendamento;
  final DateTime dataSelecionada;
  final VoidCallback onAgendamentoSalvo;

  const FormularioAgendamento({
    required this.salaoId,
    required this.modoAgendamento,
    required this.dataSelecionada,
    required this.onAgendamentoSalvo,
    super.key,
  });

  @override
  State<FormularioAgendamento> createState() => _FormularioAgendamentoState();
}

class _FormularioAgendamentoState extends State<FormularioAgendamento> {
  final _formKey = GlobalKey<FormState>();
  String? profissionalId;
  String? servicoId;
  String? clienteId;
  String? horario;

  List<Map<String, dynamic>> profissionais = [];
  List<Map<String, dynamic>> servicos = [];
  List<Map<String, dynamic>> clientes = [];
  List<String> horarios = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    await Future.wait([
      carregarProfissionais(),
      carregarServicos(),
      carregarClientes(),
    ]);
  }

  Future<void> carregarHorariosServicos() async {
    if (servicoId == null) return;

    final diaSemana = _diaSemana(widget.dataSelecionada.weekday);

    final response = await Supabase.instance.client
        .from('horarios_servicos')
        .select('horario')
        .eq('servico_id', servicoId)
        .eq('dia_semana', diaSemana)
        .eq('ativo', true)
        .order('horario');

    setState(() {
      horarios = List<String>.from(response.map((h) => h['horario'].toString().substring(0, 5)));
    });
  }

  String _diaSemana(int weekday) {
    const dias = {
      1: 'Segunda',
      2: 'Terça',
      3: 'Quarta',
      4: 'Quinta',
      5: 'Sexta',
      6: 'Sábado',
      7: 'Domingo',
    };
    return dias[weekday]!;
  }

  Future<void> carregarProfissionais() async {
    final response = await Supabase.instance.client
        .from('profissionais')
        .select()
        .eq('salao_id', widget.salaoId)
        .order('nome');

    setState(() {
      profissionais = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> carregarServicos() async {
    final response = await Supabase.instance.client
        .from('servicos')
        .select()
        .eq('salao_id', widget.salaoId)
        .order('nome');

    setState(() {
      servicos = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> carregarClientes() async {
    final response = await Supabase.instance.client
        .from('clientes')
        .select()
        .eq('salao_id', widget.salaoId)
        .order('nome');

    setState(() {
      clientes = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> salvarAgendamento() async {
    if (!_formKey.currentState!.validate()) return;

    final partesHora = horario!.split(':');
    final dataHora = DateTime(
      widget.dataSelecionada.year,
      widget.dataSelecionada.month,
      widget.dataSelecionada.day,
      int.parse(partesHora[0]),
      int.parse(partesHora[1]),
    );

    final supabase = Supabase.instance.client;

    try {
      if (widget.modoAgendamento == 'por_servico') {
        final servico = await supabase
            .from('servicos')
            .select('especialidade_id')
            .eq('id', servicoId)
            .maybeSingle();

        if (servico == null || servico['especialidade_id'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço sem especialidade vinculada')),
          );
          return;
        }

        final especialidadeId = servico['especialidade_id'].toString();

        final profissionaisDaEspecialidade = await supabase
            .from('profissionais')
            .select('id')
            .eq('especialidade_id', especialidadeId)
            .eq('salao_id', widget.salaoId);

        final idsProfissionais = profissionaisDaEspecialidade.map((p) => p['id'].toString()).toList();

        for (final id in idsProfissionais) {
          final conflito = await supabase
              .from('agendamentos')
              .select()
              .eq('profissional_id', id)
              .eq('data_hora', dataHora.toUtc())
              .in_('status', ['pendente', 'confirmado'])
              .maybeSingle();

          if (conflito == null) {
            await supabase.from('agendamentos').insert({
              'salao_id': widget.salaoId,
              'servico_id': servicoId,
              'cliente_id': clienteId,
              'profissional_id': id,
              'data_hora': dataHora.toUtc().toIso8601String(),
              'status': 'pendente',
            });

            widget.onAgendamentoSalvo();
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum profissional disponível para este serviço neste horário')),
        );
      } else {
        final conflito = await supabase
            .from('agendamentos')
            .select()
            .eq('profissional_id', profissionalId)
            .eq('data_hora', dataHora.toUtc())
            .in_('status', ['pendente', 'confirmado'])
            .maybeSingle();

        if (conflito != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este profissional já possui agendamento neste horário')),
          );
          return;
        }

        await supabase.from('agendamentos').insert({
          'salao_id': widget.salaoId,
          'profissional_id': profissionalId,
          'servico_id': servicoId,
          'cliente_id': clienteId,
          'data_hora': dataHora.toUtc().toIso8601String(),
          'status': 'pendente',
        });

        widget.onAgendamentoSalvo();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: clienteId,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: clientes.map((c) => DropdownMenuItem<String>(
              value: c['id'].toString(),
              child: Text(c['nome'].toString()),
            )).toList(),
            onChanged: (value) => setState(() => clienteId = value),
            validator: (value) => value == null ? 'Selecione o cliente' : null,
          ),
          DropdownButtonFormField<String>(
            value: servicoId,
            decoration: const InputDecoration(labelText: 'Serviço'),
            items: servicos.map((s) => DropdownMenuItem<String>(
              value: s['id'].toString(),
              child: Text(s['nome'].toString()),
            )).toList(),
            onChanged: (value) async {
              setState(() {
                servicoId = value;
                horario = null;
                horarios = [];
              });
              await carregarHorariosServicos();
            },
            validator: (value) => value == null ? 'Selecione o serviço' : null,
          ),
          if (widget.modoAgendamento == 'por_profissional') ...[
            DropdownButtonFormField<String>(
              value: profissionalId,
              decoration: const InputDecoration(labelText: 'Profissional'),
              items: profissionais.map((p) => DropdownMenuItem<String>(
                value: p['id'].toString(),
                child: Text(p['nome'].toString()),
              )).toList(),
              onChanged: (value) => setState(() => profissionalId = value),
              validator: (value) => value == null ? 'Selecione o profissional' : null,
            ),
          ],
          DropdownButtonFormField<String>(
            value: horario,
            decoration: const InputDecoration(labelText: 'Horário'),
            items: horarios.map((h) => DropdownMenuItem<String>(
              value: h,
              child: Text(h),
            )).toList(),
            onChanged: (value) => setState(() => horario = value),
            validator: (value) => value == null ? 'Selecione o horário' : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: salvarAgendamento,
            child: const Text('Salvar Agendamento'),
          ),
        ],
      ),
    );
  }
}
