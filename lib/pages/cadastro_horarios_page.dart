import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroHorariosPage extends StatefulWidget {
  final String salaoId;

  const CadastroHorariosPage({required this.salaoId, super.key});

  @override
  State<CadastroHorariosPage> createState() => _CadastroHorariosPageState();
}

class _CadastroHorariosPageState extends State<CadastroHorariosPage> {
  String? especialidadeId;
  String? diaSelecionado;
  TimeOfDay? horarioSelecionado;

  List<Map<String, dynamic>> especialidades = [];
  List<Map<String, dynamic>> horariosCadastrados = [];

  final diasSemana = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    carregarEspecialidades();
  }

  Future<void> carregarEspecialidades() async {
    final response = await Supabase.instance.client
        .from('especialidades')
        .select()
        .eq('salao_id', widget.salaoId)
        .order('nome');

    setState(() {
      especialidades = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> carregarHorarios() async {
    if (especialidadeId == null || diaSelecionado == null) return;

    final response = await Supabase.instance.client
        .from('horarios_especialidades')
        .select()
        .eq('especialidade_id', especialidadeId)
        .eq('dia_semana', diaSelecionado)
        .eq('ativo', true)
        .order('horario');

    setState(() {
      horariosCadastrados = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> adicionarHorario() async {
    if (especialidadeId == null || diaSelecionado == null || horarioSelecionado == null) return;

    final horarioFormatado = '${horarioSelecionado!.hour.toString().padLeft(2, '0')}:${horarioSelecionado!.minute.toString().padLeft(2, '0')}:00';

    try {
      final existe = await Supabase.instance.client
          .from('horarios_especialidades')
          .select()
          .eq('especialidade_id', especialidadeId)
          .eq('dia_semana', diaSelecionado)
          .eq('horario', horarioFormatado)
          .maybeSingle();

      if (existe != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse horário já está cadastrado')),
        );
        return;
      }

      await Supabase.instance.client.from('horarios_especialidades').insert({
        'especialidade_id': especialidadeId,
        'dia_semana': diaSelecionado,
        'horario': horarioFormatado,
        'ativo': true,
      });

      setState(() => horarioSelecionado = null);
      await carregarHorarios();
    } catch (e) {
      print('Erro ao inserir horário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar horário: $e')),
      );
    }
  }

  Future<void> excluirHorario(String id) async {
    await Supabase.instance.client
        .from('horarios_especialidades')
        .delete()
        .eq('id', id);

    await carregarHorarios();
  }

  Future<void> editarHorario(String id, String horarioAtual) async {
    final partes = horarioAtual.split(':');
    final hora = int.parse(partes[0]);
    final minuto = int.parse(partes[1]);

    final novoHorario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hora, minute: minuto),
    );

    if (novoHorario == null) return;

    final novoFormatado = '${novoHorario.hour.toString().padLeft(2, '0')}:${novoHorario.minute.toString().padLeft(2, '0')}:00';

    final duplicado = await Supabase.instance.client
        .from('horarios_especialidades')
        .select()
        .eq('especialidade_id', especialidadeId)
        .eq('dia_semana', diaSelecionado)
        .eq('horario', novoFormatado)
        .maybeSingle();

    if (duplicado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esse horário já está cadastrado')),
      );
      return;
    }

    await Supabase.instance.client
        .from('horarios_especialidades')
        .update({'horario': novoFormatado})
        .eq('id', id);

    await carregarHorarios();
  }

  Future<void> selecionarHorario() async {
    final resultado = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (resultado != null) {
      setState(() => horarioSelecionado = resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horários por Especialidade')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: especialidadeId,
              decoration: const InputDecoration(labelText: 'Especialidade'),
              items: especialidades.map((e) => DropdownMenuItem<String>(
                value: e['id'].toString(),
                child: Text(e['nome'].toString()),
              )).toList(),
              onChanged: (value) {
                setState(() => especialidadeId = value);
                carregarHorarios();
              },
            ),
            DropdownButtonFormField<String>(
              value: diaSelecionado,
              decoration: const InputDecoration(labelText: 'Dia da semana'),
              items: diasSemana.map((d) => DropdownMenuItem<String>(
                value: d,
                child: Text(d),
              )).toList(),
              onChanged: (value) {
                setState(() => diaSelecionado = value);
                carregarHorarios();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(horarioSelecionado == null
                      ? 'Nenhum horário selecionado'
                      : 'Horário: ${horarioSelecionado!.format(context)}'),
                ),
                ElevatedButton(
                  onPressed: selecionarHorario,
                  child: const Text('Selecionar Horário'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: adicionarHorario,
              child: const Text('Adicionar Horário'),
            ),
            const SizedBox(height: 20),
            const Text('Horários cadastrados:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: horariosCadastrados.length,
                itemBuilder: (_, index) {
                  final h = horariosCadastrados[index];
                  return ListTile(
                    title: Text(h['horario']),
                    subtitle: Text(h['dia_semana']),
                    trailing: SizedBox(
                      width: 96,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Editar horário',
                            onPressed: () => editarHorario(h['id'], h['horario']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Excluir horário',
                            onPressed: () => excluirHorario(h['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
