import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ConfiguracaoAgendaProfissionalPage extends StatefulWidget {
  final String profissionalId;
  final String nomeProfissional;

  const ConfiguracaoAgendaProfissionalPage({
    super.key,
    required this.profissionalId,
    required this.nomeProfissional,
  });

  @override
  _ConfiguracaoAgendaProfissionalPageState createState() => _ConfiguracaoAgendaProfissionalPageState();
}

class _ConfiguracaoAgendaProfissionalPageState extends State<ConfiguracaoAgendaProfissionalPage> {
  final supabase = Supabase.instance.client;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<String> _diasBloqueadosStrings = {}; 
  bool _isLoading = true;
  
  final Color laranjaApp = const Color(0xFFFF6D00);
  final Color vermelhoForte = const Color(0xFFD32F2F); 

  @override
  void initState() {
    super.initState();
    _carregarBloqueios();
  }

  Future<void> _carregarBloqueios() async {
    try {
      final data = await supabase
          .from('profissional_agenda_config')
          .select('data')
          .eq('profissional_id', widget.profissionalId)
          .eq('trabalha', false);

      final novasDatas = (data as List)
          .map((item) => item['data'].toString())
          .toSet();

      if (mounted) {
        setState(() {
          _diasBloqueadosStrings = novasDatas;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarOpcoesDoDia(DateTime date) {
    String dataIso = DateFormat('yyyy-MM-dd').format(date);
    bool estaFechado = _diasBloqueadosStrings.contains(dataIso);
    
    TextEditingController motivoController = TextEditingController();
    String dataFormatada = DateFormat('dd/MM/yyyy').format(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20, left: 20, right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Folga: ${widget.nomeProfissional}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text("Data: $dataFormatada", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text("O profissional trabalhará neste dia?"),
                  value: !estaFechado,
                  activeColor: laranjaApp,
                  onChanged: (val) => setModalState(() => estaFechado = !val),
                ),
                if (estaFechado)
                  TextField(
                    controller: motivoController,
                    decoration: const InputDecoration(labelText: "Motivo", border: OutlineInputBorder()),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: laranjaApp),
                    onPressed: () => _salvarConfiguracao(date, !estaFechado, motivoController.text),
                    child: const Text("Salvar Alteração", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _salvarConfiguracao(DateTime date, bool trabalha, String motivo) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase.from('profiles').select('salao_id').eq('id', user.id).single();
      
      await supabase.from('profissional_agenda_config').upsert({
        'salao_id': res['salao_id'],
        'profissional_id': widget.profissionalId,
        'data': dateString,
        'trabalha': trabalha,
        'motivo': motivo,
      }, onConflict: 'profissional_id,data');

      await _carregarBloqueios(); 

      if (mounted) {
        setState(() {
          _selectedDay = null; 
        });
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Erro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Gerenciar Folgas", style: TextStyle(color: t.colorScheme.onPrimary)),
        backgroundColor: t.colorScheme.primary,
        iconTheme: IconThemeData(color: t.colorScheme.onPrimary),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const SizedBox(height: 10),
              // NOME DO PROFISSIONAL EM DESTAQUE (Print 03)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Profissional: ${widget.nomeProfissional}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: TableCalendar(
                    locale: 'pt_BR',
                    focusedDay: _focusedDay,
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _mostrarOpcoesDoDia(selectedDay);
                    },
                    onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        border: Border.all(color: laranjaApp, width: 2),
                        shape: BoxShape.circle
                      ),
                      todayTextStyle: TextStyle(color: t.colorScheme.primary),
                      selectedDecoration: BoxDecoration(color: laranjaApp, shape: BoxShape.circle),
                    ),
                    calendarBuilders: CalendarBuilders(
                      prioritizedBuilder: (context, day, focusedDay) {
                        String d = DateFormat('yyyy-MM-dd').format(day);
                        if (_diasBloqueadosStrings.contains(d)) {
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: vermelhoForte, shape: BoxShape.circle),
                            child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                          );
                        }
                        return null;
                      },
                    ),
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: vermelhoForte, radius: 6),
                    const SizedBox(width: 10),
                    const Text("Folga do profissional"),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}