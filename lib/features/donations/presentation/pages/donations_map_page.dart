import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';
import 'package:feed_the_future/core/routes/app_router.dart';
import 'package:feed_the_future/features/donations/domain/entities/donation.dart';
import 'package:feed_the_future/features/donations/presentation/providers/donation_provider.dart';
import 'package:feed_the_future/features/donations/presentation/widgets/donation_card.dart';
import 'package:go_router/go_router.dart';

class DonationsMapPage extends ConsumerStatefulWidget {
  const DonationsMapPage({super.key});

  @override
  ConsumerState<DonationsMapPage> createState() => _DonationsMapPageState();
}

class _DonationsMapPageState extends ConsumerState<DonationsMapPage> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  Donation? _selectedDonation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 12,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationsAsync = ref.watch(availableDonationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Donaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildMap(donationsAsync),
          if (_selectedDonation != null)
            _buildDonationDetails(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMap(AsyncValue<List<Donation>> donationsAsync) {
    return donationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(availableDonationsProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (donations) {
        _updateMarkers(donations);
        
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? const LatLng(19.4326, -99.1332), // CDMX default
            zoom: 12,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_currentLocation != null) {
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _currentLocation!,
                    zoom: 12,
                  ),
                ),
              );
            }
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        );
      },
    );
  }

  void _updateMarkers(List<Donation> donations) {
    final markers = <Marker>{};
    
    for (final donation in donations) {
      final marker = Marker(
        markerId: MarkerId(donation.id),
        position: LatLng(
          donation.location!.latitude,
          donation.location!.longitude,
        ),
        infoWindow: InfoWindow(
          title: donation.name,
          snippet: '${donation.quantity} ${donation.unit}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          donation.status == 'available' 
              ? BitmapDescriptor.hueGreen 
              : BitmapDescriptor.hueOrange,
        ),
        onTap: () => _onMarkerTapped(donation),
      );
      markers.add(marker);
        }
    
    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTapped(Donation donation) {
    setState(() {
      _selectedDonation = donation;
    });
  }

  Widget _buildDonationDetails() {
    if (_selectedDonation == null) return const SizedBox();

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDonation!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedDonation = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedDonation!.quantity} ${_selectedDonation!.unit}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedDonation!.description.isNotEmpty)
                Text(
                  _selectedDonation!.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _selectedDonation!.location.address ?? 'Ubicación no disponible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.go(AppRoutes.donationDetail(_selectedDonation!.id));
                      },
                      child: const Text('Ver Detalles'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.directions),
                    onPressed: () => _openDirections(_selectedDonation!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Donaciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtrar por categoría:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                'Comida',
                'Ropa',
                'Medicinas',
                'Otros',
              ].map((category) {
                return FilterChip(
                  label: Text(category),
                  onSelected: (selected) {
                    // TODO: Implement filter logic
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _openDirections(Donation donation) {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${donation.location.latitude},${donation.location.longitude}';
    // TODO: Open URL using url_launcher
  }
}
