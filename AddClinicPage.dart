import 'package:flutter/material.dart';
import 'ClinicListScreen.dart'; // For the Clinic model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinic.dart';

class AddClinicPage extends StatefulWidget {
  final Function(Clinic) onClinicAdded;

  AddClinicPage({required this.onClinicAdded});

  @override
  _AddClinicPageState createState() => _AddClinicPageState();
}

class _AddClinicPageState extends State<AddClinicPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<Map<String, TextEditingController>> _services = [];
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _addServiceField(); // Add one service field by default
  }

  void _addServiceField() {
    setState(() {
      _services.add({
        'name': TextEditingController(),
        'duration': TextEditingController(),
      });
    });
  }

  void _removeServiceField(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  void _submitClinic() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _clinicNameController.text.trim();
    final password = _passwordController.text.trim();
    final Map<String, String> servicesWithTime = {};

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    for (var service in _services) {
      final serviceName = service['name']!.text.trim();
      final duration = service['duration']!.text.trim();
      servicesWithTime[serviceName] = 'Approx. $duration';
    }

    try {
      final docRef = await FirebaseFirestore.instance.collection('clinics').add({
        'name': name,
        'servicesWithTime': servicesWithTime,
        'rating': 0.0,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newClinic = Clinic(
        id: docRef.id,
        name: name,
        servicesWithTime: servicesWithTime,
        rating: 0.0,
        password: password,
      );

      widget.onClinicAdded(newClinic);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clinic added successfully.')),
      );
    } catch (e) {
      print('Error adding clinic to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add clinic. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Clinic')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Clinic Name', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextFormField(
                controller: _clinicNameController,
                validator: (val) => val == null || val.isEmpty ? 'Enter clinic name' : null,
                decoration: InputDecoration(hintText: 'e.g. Healthy Life Clinic'),
              ),

              SizedBox(height: 24),
              Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (val) => val == null || val.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
                decoration: InputDecoration(
                  hintText: 'Enter a password for the clinic',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: 24),
              Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._services.asMap().entries.map((entry) {
                int index = entry.key;
                var serviceControllers = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: serviceControllers['name'],
                          validator: (val) => val == null || val.isEmpty ? 'Service name' : null,
                          decoration: InputDecoration(hintText: 'Service Name'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        width: 100,
                        child: TextFormField(
                          controller: serviceControllers['duration'],
                          validator: (val) => val == null || val.isEmpty ? 'Duration' : null,
                          decoration: InputDecoration(hintText: '15 mins'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: _services.length > 1
                            ? () => _removeServiceField(index)
                            : null,
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 10),
              TextButton.icon(
                onPressed: _addServiceField,
                icon: Icon(Icons.add),
                label: Text('Add Another Service'),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.check),
                label: Text('Submit Clinic'),
                onPressed: _submitClinic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
