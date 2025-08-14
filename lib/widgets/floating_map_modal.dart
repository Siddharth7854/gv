import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../core/theme/gov_theme.dart';

/// WhatsApp-style floating map modal for showing grievance location
class FloatingMapModal extends StatefulWidget {
  final double? grievanceLatitude;
  final double? grievanceLongitude;
  final String? grievanceTitle;
  final String? grievanceAddress;

  const FloatingMapModal({
    super.key,
    this.grievanceLatitude,
    this.grievanceLongitude,
    this.grievanceTitle,
    this.grievanceAddress,
  });

  @override
  State<FloatingMapModal> createState() => _FloatingMapModalState();
}

class _FloatingMapModalState extends State<FloatingMapModal>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Set<Marker> _markers = {};
  LatLng? _grievanceLocation;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _initializeMap();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (widget.grievanceLatitude != null &&
          widget.grievanceLongitude != null) {
        _grievanceLocation = LatLng(
          widget.grievanceLatitude!,
          widget.grievanceLongitude!,
        );
      }

      if (_currentPosition != null) {
        _currentLocation = LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      _updateMarkers();

      setState(() {
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};

    // Add grievance location marker
    if (_grievanceLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('grievance_location'),
          position: _grievanceLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.grievanceTitle ?? 'Grievance Location',
            snippet: widget.grievanceAddress ?? 'Reported issue location',
          ),
        ),
      );
    }

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitMarkersInView();
  }

  void _fitMarkersInView() {
    if (_mapController == null) return;

    if (_grievanceLocation != null && _currentLocation != null) {
      // Fit both markers
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          [
            _grievanceLocation!.latitude,
            _currentLocation!.latitude,
          ].reduce((a, b) => a < b ? a : b),
          [
            _grievanceLocation!.longitude,
            _currentLocation!.longitude,
          ].reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          [
            _grievanceLocation!.latitude,
            _currentLocation!.latitude,
          ].reduce((a, b) => a > b ? a : b),
          [
            _grievanceLocation!.longitude,
            _currentLocation!.longitude,
          ].reduce((a, b) => a > b ? a : b),
        ),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } else if (_grievanceLocation != null) {
      // Show only grievance location
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_grievanceLocation!, 15.0),
      );
    } else if (_currentLocation != null) {
      // Show only current location
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: GestureDetector(
        onTap: _closeModal,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on modal
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: GovTheme.primaryBlue,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location Details',
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (widget.grievanceTitle != null)
                                    Text(
                                      widget.grievanceTitle!,
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _closeModal,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Map Container
                      SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: _isLoadingLocation
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        GovTheme.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Loading location...',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: GovTheme.neutralGray,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : kIsWeb
                            ? _buildWebMapPlaceholder()
                            : GoogleMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition: CameraPosition(
                                  target:
                                      _grievanceLocation ??
                                      _currentLocation ??
                                      const LatLng(
                                        28.6139,
                                        77.2090,
                                      ), // Delhi as fallback
                                  zoom: 15.0,
                                ),
                                markers: _markers,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                compassEnabled: true,
                                zoomControlsEnabled: true,
                                mapToolbarEnabled: true,
                                buildingsEnabled: true,
                                trafficEnabled: false,
                                mapType: MapType.normal,
                              ),
                      ),

                      // Location Info Footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_grievanceLocation != null) ...[
                              _buildLocationInfo(
                                'Grievance Location',
                                Icons.error_outline,
                                GovTheme.errorRed,
                                '${_grievanceLocation!.latitude.toStringAsFixed(6)}, ${_grievanceLocation!.longitude.toStringAsFixed(6)}',
                                widget.grievanceAddress,
                              ),
                              if (_currentLocation != null) ...[
                                const SizedBox(height: 12),
                                Divider(
                                  color: GovTheme.neutralGray.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                            if (_currentLocation != null)
                              _buildLocationInfo(
                                'Your Current Location',
                                Icons.my_location,
                                GovTheme.primaryBlue,
                                '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                                'Live location',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    String title,
    IconData icon,
    Color color,
    String coordinates,
    String? address,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GovTheme.darkGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                coordinates,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: GovTheme.neutralGray,
                ),
              ),
              if (address != null) ...[
                const SizedBox(height: 2),
                Text(
                  address,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: GovTheme.neutralGray.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebMapPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GovTheme.primaryBlue.withOpacity(0.05),
            GovTheme.secondaryBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GovTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              size: 48,
              color: GovTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Interactive Map',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: GovTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Interactive maps are not fully supported on this platform.',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: GovTheme.neutralGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'View location details below or open in your browser.',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: GovTheme.neutralGray.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_grievanceLocation != null)
            ElevatedButton.icon(
              onPressed: () async {
                final url =
                    'https://www.google.com/maps/search/?api=1&query=${_grievanceLocation!.latitude},${_grievanceLocation!.longitude}';
                // For web, we can use window.open or similar
                if (kIsWeb) {
                  // On web, we can use url_launcher or window.open
                  debugPrint('Opening URL: $url');
                  // Note: For now just log, in production you'd use url_launcher
                } else {
                  debugPrint('Desktop platform detected - would open browser');
                }
              },
              icon: const Icon(Icons.open_in_browser, size: 16),
              label: const Text('Open in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GovTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
