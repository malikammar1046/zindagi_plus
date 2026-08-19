import 'package:flutter/material.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class NearbyFacilitiesScreen extends StatelessWidget {
  const NearbyFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Facilities'),
        leading: const AppBackButton(fallbackLocation: '/activities'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 80,
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Map View (Placeholder)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // List of Facilities
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SectionHeader(title: 'Recommended for you'),
                  const SizedBox(height: 12),
                  _FacilityTile(
                    name: 'City General Hospital',
                    type: 'Hospital',
                    distance: '1.2 km',
                    isOpen: true,
                  ),
                  const SizedBox(height: 8),
                  _FacilityTile(
                    name: 'Greenwood Pharmacy',
                    type: 'Pharmacy',
                    distance: '0.5 km',
                    isOpen: true,
                  ),
                  const SizedBox(height: 8),
                  _FacilityTile(
                    name: 'Downtown Medical Clinic',
                    type: 'Clinic',
                    distance: '2.4 km',
                    isOpen: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
    required this.name,
    required this.type,
    required this.distance,
    required this.isOpen,
  });

  final String name;
  final String type;
  final String distance;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData icon;
    if (type == 'Hospital') {
      icon = Icons.local_hospital_rounded;
    } else if (type == 'Pharmacy') {
      icon = Icons.local_pharmacy_rounded;
    } else {
      icon = Icons.medical_services_rounded;
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $distance',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen 
                  ? colorScheme.primary.withValues(alpha: 0.1) 
                  : colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOpen ? 'Open' : 'Closed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOpen ? colorScheme.primary : colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
