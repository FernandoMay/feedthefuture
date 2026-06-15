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
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:feed_the_future/core/services/storage_service.dart';
import 'package:feed_the_future/core/widgets/location_search_delegate.dart';
import 'package:feed_the_future/core/services/location_service.dart';

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
  bool _localeInitialized = false;

  // Map and location variables
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  Set<Marker> _markers = {};
  bool _locationLoading = false;

  // Image variables
  File? _imageFile;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Inicializar locale para formateo de fechas
    _initializeLocale();
    // Obtener ubicación actual
    _getCurrentLocation();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es');
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    
    try {
      // Verificar permisos de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Solicitar que activen los servicios de ubicación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor activa los servicios de ubicación'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
        setState(() => _locationLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permiso de ubicación denegado'),
                backgroundColor: AppTheme.dangerRed,
              ),
            );
          }
          setState(() => _locationLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado permanentemente. Ve a configuración para habilitarlo.'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
        setState(() => _locationLoading = false);
        return;
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _markers = {
            Marker(
              markerId: const MarkerId('current_location'),
              position: _currentLocation,
              infoWindow: const InfoWindow(title: 'Tu ubicación'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          };
          _locationLoading = false;
        });

        // Mover el mapa a la ubicación actual
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation,
                zoom: 15.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error obteniendo ubicación: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
      setState(() => _locationLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Mover el mapa a la ubicación actual cuando se crea
    if (_currentLocation.latitude != AppConstants.defaultLatitude) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _onMapTap(LatLng location) async {
    setState(() {
      _currentLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Ubicación de recolección'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };
    });

    // Obtener dirección desde coordenadas (geocodificación inversa)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude, 
        location.longitude,
      );
      
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];
        
        // Construir dirección con más detalles disponibles
        if (place.thoroughfare?.isNotEmpty == true) {
          addressParts.add(place.thoroughfare!);
        }
        if (place.subThoroughfare?.isNotEmpty == true) {
          addressParts.add(place.subThoroughfare!);
        }
        if (place.subLocality?.isNotEmpty == true) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty == true) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty == true) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode?.isNotEmpty == true) {
          addressParts.add('CP ${place.postalCode!}');
        }
        if (place.country?.isNotEmpty == true) {
          addressParts.add(place.country!);
        }
        
        // Si la dirección es muy corta o solo contiene país, agregar coordenadas
        if (addressParts.length <= 2) {
          addressParts.add('(Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)})');
        }
        
        String address = addressParts.join(', ');
        
        // Actualizar campo de dirección
        _addressCtrl.text = address.isNotEmpty ? address : 'Ubicación seleccionada en mapa';
        
        // Mostrar snackbar de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dirección: ${address.length > 60 ? '${address.substring(0, 60)}...' : address}'),
            backgroundColor: AppTheme.greenFresh,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _addressCtrl.text = 'Ubicación seleccionada en mapa (Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usando coordenadas: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
  
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Usuario no autenticado'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
      return;
    }

    String? imageUrl;
    if (_imageFile != null) {
      final storageService = ref.read(storageServiceProvider);
      final filename = 'donations/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadResult = await storageService.uploadImage(
        imageFile: _imageFile!,
        path: filename, 
      );
      uploadResult.fold(
        (failure) {}, // Ignore errors for now or log them
        (url) {
          imageUrl = url;
        }
      );
    }

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
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        address: _addressCtrl.text.trim().isNotEmpty 
            ? _addressCtrl.text.trim() 
            : 'Ubicación seleccionada en mapa',
        city: 'CDMX',
      ),
      photoUrls: imageUrl != null ? [imageUrl!] : const [],
      assignedNgoId: null,
      assignedNgoName: null,
      assignedVolunteerId: null,
      weightKg: null,
      nutritionInfo: null,
    );

    try {
      // Agregar timeout de 10 segundos
      final ok = await ref.read(donationCreateProvider.notifier).create(donation).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Tiempo de espera agotado', const Duration(seconds: 10));
        },
      );

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
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        String errorMessage = 'Error al registrar donación';
        
        if (e is TimeoutException) {
          errorMessage = 'Tiempo de espera agotado. Verifica tu conexión.';
        } else if (e.toString().contains('NOT_FOUND')) {
          errorMessage = 'Error de conexión. Verifica tu internet.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _submit(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esperar a que el locale esté inicializado
    if (!_localeInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _loading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _loading && _currentStep == 2 
                          ? AppTheme.greenLime.withValues(alpha: 0.7)
                          : null,
                    ),
                    child: _loading && _currentStep == 2
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.greenLime,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Registrando...'),
                            ],
                          )
                        : Text(
                            _currentStep == 2 ? 'Registrar donación' : 'Siguiente',
                            style: const TextStyle(fontFamily: 'DMSans'),
                          ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loading ? null : details.onStepCancel,
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.cream,
                        border: Border.all(color: const Color(0x1A2D8A55)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imageFile != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 40, color: AppTheme.textMuted),
                              SizedBox(height: 8),
                              Text('Agregar foto del alimento (Opcional)', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                        items: AppConstants.weightUnits
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unit = v!),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dirección de recolección',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.greenFresh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () async {
                            final PlaceDetails? result = await showSearch<PlaceDetails?>(
                              context: context,
                              delegate: LocationSearchDelegate(ref),
                            );

                            if (result != null) {
                              setState(() {
                                _addressCtrl.text = result.address;
                                _currentLocation = LatLng(result.lat, result.lng);
                                _markers = {
                                  Marker(
                                    markerId: const MarkerId('selected_location'),
                                    position: _currentLocation,
                                    infoWindow: const InfoWindow(title: 'Ubicación seleccionada'),
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                  ),
                                };
                              });

                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(target: _currentLocation, zoom: 16.0),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0x0D2D8A55),
                      borderRadius: BorderRadius.circular(16),
                      border: const Border.fromBorderSide(
                        BorderSide(color: Color(0x1A2D8A55), width: 1.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15.0,
            ),
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          if (_locationLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.greenFresh,
                    ),
                    SizedBox(height: 8),
                    Text('Obteniendo ubicación...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  ),
  const SizedBox(height: 8),
  Text(
    'Toca el mapa para seleccionar la ubicación de recolección',
    style: AppTextStyles.caption.copyWith(
      color: AppTheme.textMuted,
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
