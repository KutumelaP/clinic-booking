import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'BookingScreen.dart';
import 'AdminPage.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'WelcomeScreen.dart';
import 'clinic.dart';

class ClinicListScreen extends StatefulWidget {
  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  List<Clinic> allClinics = [];
  String query = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinicsFromFirestore();
  }

  Future<void> _loadClinicsFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('clinics').get();

    final clinics = snapshot.docs.map((doc) {
      final data = doc.data();
      return Clinic(
         id: doc.id, // ✅ Set Firestore doc ID here
        name: data['name'] ?? '',
        servicesWithTime: Map<String, String>.from(data['servicesWithTime'] ?? {}),
        rating: (data['rating'] ?? 0.0).toDouble(),
      );
    }).toList();

    setState(() {
      allClinics = clinics;
      _isLoading = false;
    });
  }

  Widget buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.amber, size: 18));
    }
    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.amber, size: 18));
    }
    while (stars.length < 5) {
      stars.add(Icon(Icons.star_border, color: Colors.amber, size: 18));
    }

    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final filteredClinics = allClinics
        .where((clinic) => clinic.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
    appBar: AppBar(
      title: Text('Find a Clinic'),
      actions: [
      IconButton(
      icon: Icon(Icons.home),
      tooltip: 'Go to Home',
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => WelcomeScreen()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      },
    ),
        if (kIsWeb)
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            tooltip: 'Admin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminPage()),
              );
            },
          ),
      ],
    ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Text(
                    'Available Clinics',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search clinic...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => query = value);
                    },
                  ),
                ),

                SizedBox(height: 10),

                Expanded(
                  child: filteredClinics.isEmpty
                      ? Center(child: Text('No clinics found.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredClinics.length,
                          itemBuilder: (context, index) {
                            final clinic = filteredClinics[index];
                            final topServices = clinic.servicesWithTime.keys.take(2).toList();

                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              shadowColor: Colors.teal.withOpacity(0.2),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal[100],
                                  child: Icon(Icons.local_hospital, color: Colors.teal[700]),
                                  radius: 28,
                                ),
                                title: Text(clinic.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 6),
                                    Text(
                                      'Top Services: ${topServices.join(', ')}',
                                      style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                                    ),
                                    SizedBox(height: 6),
                                    buildRatingStars(clinic.rating),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal[400]),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => BookingScreen(clinic: clinic)),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
