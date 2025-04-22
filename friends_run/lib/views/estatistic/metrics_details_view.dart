import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_run/core/providers/metrics_provider.dart';
import 'package:friends_run/core/utils/colors.dart';
import 'package:friends_run/core/utils/metrics_calculator.dart'; // Importar calculadora
import 'package:friends_run/models/user/my_race_metrics.dart';
import 'package:friends_run/views/race/race_details/race_details_view.dart';
import 'package:intl/intl.dart';

class MetricsDetailsView extends ConsumerStatefulWidget {
  final MyRaceMetrics initialMetrics;

  const MetricsDetailsView({required this.initialMetrics, super.key});

  @override
  ConsumerState<MetricsDetailsView> createState() => _MetricsDetailsViewState();
}

class _MetricsDetailsViewState extends ConsumerState<MetricsDetailsView> {
  late DateTime _editedEndTime;
  late MyRaceMetrics _currentMetrics; // Guarda o estado mais recente (original ou salvo)
  bool _hasChanges = false; // Flag para indicar se _editedEndTime foi modificado
  bool _isSaving = false; // Flag para indicar estado de loading do save

  final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
  // final DateFormat _timeFormatter = DateFormat('HH:mm:ss'); // Não usado diretamente mais

  @override
  void initState() {
    super.initState();
    _currentMetrics = widget.initialMetrics;
    _editedEndTime = widget.initialMetrics.userEndTime; // Começa com o tempo original
  }

  // --- Funções de Ação ---

  Future<void> _selectEndTime() async {
    // (Lógica do Date/Time Picker - sem alterações)
    final DateTime initialDate = _editedEndTime;
    final DateTime raceStartDate = _currentMetrics.userStartTime ?? _currentMetrics.raceDate;
    final DateTime firstAllowedDate = raceStartDate.add(const Duration(seconds: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: raceStartDate.subtract(const Duration(days: 1)), // Permite data anterior se necessário ajuste
      lastDate: DateTime.now().add(const Duration(days: 365)), // Limite futuro
    );
    if (pickedDate == null || !mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) return;

    final DateTime newEndTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);

    if (newEndTime.isBefore(firstAllowedDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('O tempo final deve ser após o início da corrida (${_dateTimeFormatter.format(raceStartDate)}).'), backgroundColor: Colors.orangeAccent, ), );
      }
      return;
    }

    if (newEndTime != _editedEndTime) {
      setState(() {
        _editedEndTime = newEndTime;
        _hasChanges = true; // Marca que há mudanças não salvas
      });
    }
  }

  // Mostra o diálogo de confirmação
  void _showSaveConfirmationDialog() {
     // Só mostra o diálogo se houver mudanças
     if (!_hasChanges || _isSaving) return;

     showDialog(
       context: context,
       builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Confirmar Alterações', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
          content: const Text('Deseja salvar o novo tempo final da corrida? As estatísticas dependentes (duração, pace, velocidade) serão recalculadas.', style: TextStyle(color: AppColors.black)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Fecha só o diálogo
              child: const Text('Cancelar', style: TextStyle(color: AppColors.greyDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                 Navigator.pop(context); // Fecha o diálogo
                 _performSaveChanges(); // Chama a função que realmente salva
              },
              child: const Text('Salvar'),
            ),
          ],
       ),
     );
  }


  // Lógica que efetivamente salva os dados (chamada após confirmação)
  Future<void> _performSaveChanges() async {
    setState(() { _isSaving = true; });

    final DateTime startTime = _currentMetrics.userStartTime ?? _currentMetrics.raceDate;
    final Duration newDuration = _editedEndTime.difference(startTime);
    final Duration newPace = MetricsCalculator.calculatePace(newDuration, _currentMetrics.distanceMeters);
    final double newSpeed = MetricsCalculator.calculateSpeedKmh(newDuration, _currentMetrics.distanceMeters);

    final updatedMetrics = _currentMetrics.copyWith(
      userEndTime: _editedEndTime,
      duration: newDuration,
      avgPacePerKm: newPace,
      avgSpeedKmh: newSpeed,
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(metricsActionNotifierProvider.notifier);
    final savedId = await notifier.saveMetrics(updatedMetrics);

    // É crucial verificar se o widget ainda está montado após chamadas async
    if (mounted) {
        setState(() { _isSaving = false; });
        if (savedId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tempo final atualizado!'), backgroundColor: Colors.green),
          );
          setState(() {
            _currentMetrics = updatedMetrics; // Atualiza o estado base com os dados salvos
            _hasChanges = false; // Reseta flag
          });
          ref.invalidate(userMetricsProvider(_currentMetrics.userId));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener para erros do save (opcional, pode já ter global)
    ref.listen<MetricsActionState>(metricsActionNotifierProvider, (_, state) {
       if (!state.isLoading && state.error != null && state.actionType == MetricsActionType.save) {
           if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro ao salvar: ${state.error}"), backgroundColor: Colors.redAccent),
               );
               // Limpa o erro no notifier
               ref.read(metricsActionNotifierProvider.notifier).clearError();
           }
       }
    });

    // Recalcula valores que dependem do tempo editado para exibição
    final displayDuration = _hasChanges
        ? _editedEndTime.difference(_currentMetrics.userStartTime ?? _currentMetrics.raceDate)
        : _currentMetrics.duration;
    final displayPace = _hasChanges
        ? MetricsCalculator.calculatePace(displayDuration, _currentMetrics.distanceMeters)
        : _currentMetrics.avgPacePerKm;


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _currentMetrics.raceTitle,
          style: const TextStyle(color: AppColors.white),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        // actions removido daqui
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Resumo Principal (com Calorias) --
            _buildMetricRow(
              icon: Icons.timer,
              label: 'Duração Total',
              value: _formatDuration(displayDuration), // Usa valor recalculado se houver mudança
              isLarge: true,
            ),
            const SizedBox(height: 10),
            _buildMetricRow(
              icon: Icons.route,
              label: 'Distância Percorrida',
              value: _currentMetrics.formattedDistance, // Distância não muda
              isLarge: true,
            ),
            const SizedBox(height: 10),
             _buildMetricRow(
              icon: Icons.speed,
              label: 'Pace Médio',
              value: _formatPace(displayPace), // Usa valor recalculado se houver mudança
              isLarge: true,
            ),
             const SizedBox(height: 10),
             // Adicionando Calorias ao resumo principal
             _buildMetricRow(
                icon: Icons.local_fire_department_outlined,
                label: 'Calorias',
                // Formata o valor, tratando null com ?? 0
                value: '${NumberFormat("#,##0", "pt_BR").format(_currentMetrics.caloriesBurned ?? 0)} kcal',
                isLarge: true, // Mantém o estilo grande
             ),

            const SizedBox(height: 24),
            Divider(color: AppColors.white.withAlpha(50)),
            const SizedBox(height: 16),

            // -- Detalhes de Tempo (Editável) --
             Text('Tempo Registrado', style: TextStyle(color: AppColors.white.withAlpha(200), fontSize: 16)),
             const SizedBox(height: 12),
            _buildEditableTimeRow(
              icon: Icons.play_arrow_rounded,
              label: 'Início:',
              time: _currentMetrics.userStartTime,
            ),
            const SizedBox(height: 8),
             _buildEditableTimeRow(
              icon: Icons.flag_rounded,
              label: 'Fim:',
              time: _editedEndTime,
              onEdit: _selectEndTime,
              hasChanges: _hasChanges,
            ),

             const SizedBox(height: 24), // Espaço antes do botão

             // -- Botão Salvar (visível apenas se houver alterações) --
             if (_hasChanges)
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 16.0),
                 child: Center(
                   child: _isSaving // Mostra loading enquanto salva
                       ? const CircularProgressIndicator(color: AppColors.primaryRed)
                       : ElevatedButton.icon(
                           icon: const Icon(Icons.save_alt_rounded),
                           label: const Text('Salvar Alterações no Tempo'),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primaryRed,
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                             textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                           ),
                           // Chama o diálogo de confirmação ao pressionar
                           onPressed: _showSaveConfirmationDialog,
                         ),
                 ),
               ),

            // -- Seção "Outras Métricas" REMOVIDA --
            // const SizedBox(height: 24),
            // Divider(color: AppColors.white.withAlpha(50)),
            // const SizedBox(height: 16),
            // Text('Outras Métricas', ...),
            // const SizedBox(height: 12),
            // Wrap( children: [ ... chips ... ],),

             const SizedBox(height: 10), // Espaço antes do link final

             // -- Link para detalhes da corrida original --
             Center( // Centraliza o botão
               child: TextButton.icon(
                   icon: Icon(Icons.info_outline, color: AppColors.greyLight, size: 18),
                   label: Text(
                      'Ver detalhes da corrida original',
                       style: TextStyle(color: AppColors.greyLight, fontSize: 14),
                   ),
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => RaceDetailsView(raceId: _currentMetrics.raceId)));
                  },
               ),
             )

          ],
        ),
      ),
    );
  }

  // Helper para linhas de métrica principais
  Widget _buildMetricRow({required IconData icon, required String label, required String value, bool isLarge = false}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: isLarge ? 26 : 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(color: AppColors.white.withAlpha(180), fontSize: isLarge ? 16 : 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                color: AppColors.white,
                fontSize: isLarge ? 22 : 18,
                fontWeight: isLarge ? FontWeight.bold : FontWeight.normal),
            textAlign: TextAlign.end, // Alinha valor à direita
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

   // Helper para linhas de tempo (com botão de editar opcional)
  Widget _buildEditableTimeRow({
    required IconData icon,
    required String label,
    required DateTime? time,
    VoidCallback? onEdit,
    bool hasChanges = false, // Para destacar se foi alterado
  }) {
    final String formattedTime = time != null ? _dateTimeFormatter.format(time) : 'N/A';
    return Row(
      children: [
        Icon(icon, color: AppColors.greyLight, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: AppColors.white.withAlpha(180), fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            formattedTime,
            style: TextStyle(
                color: hasChanges ? Colors.amber.shade300 : AppColors.white, // Destaca se mudou
                fontSize: 16,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
        // Mostra botão de editar apenas se a função onEdit for fornecida
        if (onEdit != null)
          IconButton(
            icon: Icon(Icons.edit_calendar_outlined, color: AppColors.greyLight, size: 20),
            padding: const EdgeInsets.only(left: 12),
            constraints: const BoxConstraints(), // Remove padding extra do IconButton
            tooltip: 'Editar tempo final',
            onPressed: onEdit,
          )
        else // Adiciona espaço para alinhar com a linha editável
           const SizedBox(width: 48), // Largura aproximada do IconButton + padding
      ],
    );
  }

  // Helper para os 'chips' de métricas secundárias
  Widget _buildMetricChip(IconData icon, String value, String label) {
     return Chip(
        avatar: Icon(icon, size: 18, color: AppColors.white.withAlpha(200)),
        label: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: AppColors.white.withAlpha(220)),
            children: [
              TextSpan(text: '$value ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: label, style: TextStyle(fontSize: 11, color: AppColors.white.withAlpha(160))),
            ],
          ),
        ),
        backgroundColor: AppColors.white.withAlpha(30),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        visualDensity: VisualDensity.compact,
     );
  }


  // Funções de formatação (poderiam ir para utils)
  /// Formata a duração para HHh MMm ou MMm SSs ou SSs
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      // Mostra horas e minutos se for mais de 1 hora
      return "${hours}h ${twoDigits(minutes)}m"; 
    } else if (minutes > 0) {
      // Mostra minutos e segundos se for menos de 1 hora mas mais de 1 minuto
       return "${minutes}m ${twoDigits(seconds)}s";
    } else {
      // Mostra apenas segundos se for menos de 1 minuto
      return "${seconds}s";
    }
  }

  /// Formata o pace para MM'SS" (removendo o /km para economizar espaço)
  String _formatPace(Duration pace) {
    // Retorna um placeholder se o pace for zero (evita divisão por zero ou resultado inválido)
    if (pace == Duration.zero || pace.isNegative) return "--'--\""; 
    
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = pace.inMinutes;
    // Calcula os segundos restantes *dentro* do minuto atual
    final seconds = pace.inSeconds.remainder(60); 
    
    return "$minutes'${twoDigits(seconds)}\""; // Formato MM'SS"
  }
}