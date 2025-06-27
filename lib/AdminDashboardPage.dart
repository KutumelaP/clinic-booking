import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ClinicListScreen.dart'; // For Clinic model
import 'clinic.dart';

class AdminDashboardPage extends StatefulWidget {
  final Clinic clinic;

  const AdminDashboardPage({required this.clinic, Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, String> _services;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _services = Map.from(widget.clinic.servicesWithTime);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editService(String oldName, String oldTime) async {
    final nameController = TextEditingController(text: oldName);
    final timeController = TextEditingController(text: oldTime);
    String? errorText;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(oldName.isEmpty ? 'Add Service' : 'Edit Service'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    errorText: errorText,
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (e.g. 30 mins)',
                  ),
                ),
              ],
            ),
            actions: [
              if (oldName.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Service?'),
                        content: Text('Are you sure you want to delete "$oldName"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmDelete == true) {
                      Navigator.pop(context, {'delete': oldName});
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  final newName = nameController.text.trim();
                  final newTime = timeController.text.trim();

                  if (newName.isEmpty) {
                    setState(() {
                      errorText = 'Service name cannot be empty';
                    });
                    return;
                  }
                  Navigator.pop(context, {newName: newTime});
                },
              ),
            ],
          );
        });
      },
    );

    if (result == null) return;

    // Handle deletion
    if (result.containsKey('delete')) {
      final delName = result['delete']!;
      setState(() {
        _services.remove(delName);
      });
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinic.id)
          .update({'servicesWithTime': _services});
      return;
    }

    // Handle add/edit
    final newName = result.keys.first;
    final newTime = result[newName]!;

    setState(() {
      // Remove old if changing name
      if (oldName.isNotEmpty && oldName != newName) {
        _services.remove(oldName);
      }
      _services[newName] = newTime;
    });

    await FirebaseFirestore.instance
        .collection('clinics')
        .doc(widget.clinic.id)
        .update({'servicesWithTime': _services});
  }

  Future<void> _addService() async {
    await _editService('', '');
  }

  Widget _buildServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._services.entries.map((entry) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.teal),
              title: Text(entry.key),
              subtitle: Text(entry.value),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => _editService(entry.key, entry.value),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addService,
          icon: const Icon(Icons.add),
          label: const Text('Add New Service'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    final bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('clinicId', isEqualTo: widget.clinic.id)
        .orderBy('date')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No bookings yet.', style: TextStyle(color: Colors.grey)));
        }

        final bookings = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'patient': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
            'service': data['service'] ?? '',
            'date': data['date'].toString().split('T')[0],
            'time': data['time'] ?? '',
          };
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (_, index) {
            final booking = bookings[index];
            return Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                title: Text('${booking['service']}'),
                subtitle: Text(
                  'Date: ${booking['date']}\nTime: ${booking['time']}\nPatient: ${booking['patient']}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin: ${widget.clinic.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Services'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }
}
