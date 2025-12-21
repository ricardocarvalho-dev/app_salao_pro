import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_salao_pro/widgets/cabecalho_salao_pro.dart';

class DashboardPage extends StatefulWidget {
  final String salaoId;
  const DashboardPage({required this.salaoId, super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalClientes = 0;
  int totalProfissionais = 0;
  int totalServicos = 0;
  int agendamentosHoje = 0;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final supabase = Supabase.instance.client;

    final clientes = await supabase
        .from('clientes')
        .select()
        .eq('salao_id', widget.salaoId);

    final profissionais = await supabase
        .from('profissionais')
        .select()
        .eq('salao_id', widget.salaoId);

    final servicos = await supabase
        .from('servicos')
        .select()
        .eq('salao_id', widget.salaoId);

    final agendamentos = await supabase
        .from('agendamentos')
        .select()
        .eq('salao_id', widget.salaoId)
        .eq('data', hoje);

    setState(() {
      totalClientes = clientes.length;
      totalProfissionais = profissionais.length;
      totalServicos = servicos.length;
      agendamentosHoje = agendamentos.length;
    });
  }

  Widget buildCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$value',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /*
            CabecalhoSalaoPro(
              titulo: 'Dashboard',
              mostrarLogout: false,
              salaoId: widget.salaoId,
            ),
            */
            const SizedBox(height: 12),
            Expanded(
              child: isTablet
                  ? GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        buildCard('Clientes', totalClientes, Icons.people, Colors.purple),
                        buildCard('Profissionais', totalProfissionais, Icons.person, Colors.teal),
                        buildCard('Serviços', totalServicos, Icons.cut, Colors.orange),
                        buildCard('Agendamentos Hoje', agendamentosHoje, Icons.calendar_today, Colors.blue),
                      ],
                    )
                  : ListView(
                      children: [
                        buildCard('Clientes', totalClientes, Icons.people, Colors.purple),
                        const SizedBox(height: 12),
                        buildCard('Profissionais', totalProfissionais, Icons.person, Colors.teal),
                        const SizedBox(height: 12),
                        buildCard('Serviços', totalServicos, Icons.cut, Colors.orange),
                        const SizedBox(height: 12),
                        buildCard('Agendamentos Hoje', agendamentosHoje, Icons.calendar_today, Colors.blue),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
