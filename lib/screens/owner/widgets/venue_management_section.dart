import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/futsal_venue_service.dart';
import '../../../models/futsal_venue_model.dart';

class VenueManagementSection extends StatefulWidget {
  const VenueManagementSection({Key? key}) : super(key: key);

  @override
  _VenueManagementSectionState createState() => _VenueManagementSectionState();
}

class _VenueManagementSectionState extends State<VenueManagementSection> {
  @override
  void initState() {
    super.initState();
    // Fetch venues when the section is initialized
    Provider.of<FutsalVenueService>(context, listen: false).fetchOwnerVenues();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FutsalVenueService>(
      builder: (context, venueService, child) {
        if (venueService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (venueService.error != null) {
          return Center(
            child: Text(
              'Error: ${venueService.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final venues = venueService.ownerVenues;

        if (venues.isEmpty) {
          return const Center(
            child: Text('No venues added yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            final venue = venues[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      venue.location,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Fields: ${venue.fields.length}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    // Add more venue details here
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} 