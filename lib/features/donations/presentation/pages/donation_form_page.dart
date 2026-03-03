import 'package:feed_the_future/core/constants/app_constants.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';
import 'package:feed_the_future/core/routes/app_router.dart';
import 'package:feed_the_future/features/auth/presentation/providers/auth_provider.dart';
import 'package:feed_the_future/features/donations/domain/entities/donation.dart';
import 'package:feed_the_future/features/donations/presentation/providers/donation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DonationFormPage extends ConsumerStatefulWidget {
  const DonationFormPage({super.key});

  @override
  ConsumerState<DonationFormPage> createState() => _DonationFormPageState();
}

class _DonationFormPageState extends ConsumerState<DonationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _category = 'Frutas y Verduras';
  String _unit = 'kg';
  DateTime _expiration = DateTime.now().add(const Duration(days: 2));
  bool _loading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
  
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final donation = Donation(
      id: '',
      donorId: user.id,
      donorName: user.organizationName ?? user.displayName,
      donorPhotoUrl: user.photoUrl,
      category: _category,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      quantity: double.tryParse(_qtyCtrl.text) ?? 0,
      unit: _unit,
      expirationDate: _expiration,
      createdAt: DateTime.now(),
      status: AppConstants.statusPending,
      riskScore: AppConstants.riskSafe,
      location: DonationLocation(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        address: _addressCtrl.text.trim(),
        city: 'CDMX',
      ),
      photoUrls: [],
      assignedNgoId: null,
      assignedNgoName: null,
      assignedVolunteerId: null,
      weightKg: null,
      nutritionInfo: null,
    );

    final ok = await ref.read(donationCreateProvider.notifier).create(donation);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Donación registrada exitosamente'),
          backgroundColor: AppTheme.greenFresh,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar. Intenta de nuevo.'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva donación'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _loading ? null : details.onStepContinue,
                    child: _loading && _currentStep == 2
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.greenLime,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Registrar donación' : 'Siguiente',
                            style: const TextStyle(fontFamily: 'DMSans'),
                          ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Anterior'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Alimento'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  // Category
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: AppConstants.foodCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del alimento',
                      prefixIcon: Icon(Icons.restaurant_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (estado, embalaje, etc.)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Cantidad y fecha'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (double.tryParse(v) == null) return 'Número inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit,
                          decoration: const InputDecoration(labelText: 'Unidad'),
                          items: AppConstants.weightUnits
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateTimePicker(context);
                      if (picked != null) {
                        setState(() => _expiration = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha y hora de vencimiento',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormat('d MMM yyyy, HH:mm', 'es')
                            .format(_expiration),
                        style: AppTextStyles.bodyLarge.copyWith(
                            color: AppTheme.charcoal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Ubicación'),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de recolección',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0x0D2D8A55),
                      borderRadius: BorderRadius.circular(16),
                      border: const Border.fromBorderSide(
                        BorderSide(color: Color(0x1A2D8A55), width: 1.5),
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined,
                              size: 36, color: AppTheme.greenFresh),
                          SizedBox(height: 8),
                          Text('Mapa interactivo',
                              style: AppTextStyles.bodyMedium),
                          Text('(Google Maps integrado en producción)',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiration,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return null;

    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiration),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
