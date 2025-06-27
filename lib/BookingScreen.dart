import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ClinicListScreen.dart'; // for Clinic model
import 'clinic.dart';

class BookingScreen extends StatefulWidget {
  final Clinic clinic;
  BookingScreen({required this.clinic});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _searchQuery = '';
  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // User info controllers - for the form after "Book"
  final _userFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _fileNumberController = TextEditingController();

  bool _showUserForm = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(Duration(days: 30)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _onBookPressed() {
    if (_selectedService == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select service, date, and time before booking')),
      );
      return;
    }
    setState(() {
      _showUserForm = true;
    });
  }

  Future<void> _confirmBooking() async {
    if (!_userFormKey.currentState!.validate()) return;

    final bookingData = {
      'clinicId': widget.clinic.id,
      'clinicName': widget.clinic.name,
      'service': _selectedService,
      'date': Timestamp.fromDate(_selectedDate!),
      'time': _selectedTime!.format(context),
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'idNumber': _idController.text.trim(),
      'fileNumber': _fileNumberController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending', // ✅ Add this line
    };

    try {
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Booking Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.local_hospital, color: Colors.teal),
                title: Text(widget.clinic.name),
              ),
              ListTile(
                leading: Icon(Icons.medical_services, color: Colors.teal),
                title: Text(_selectedService!),
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.teal),
                title: Text('${_selectedDate!.toLocal()}'.split(' ')[0]),
              ),
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.teal),
                title: Text(_selectedTime!.format(context)),
              ),
              ListTile(
                leading: Icon(Icons.person, color: Colors.teal),
                title: Text('${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.teal),
                title: Text(_phoneController.text.trim()),
              ),
            ],
          ),
              actions: [
      TextButton(
        child: Text('Cancel'),
        onPressed: () {
          Navigator.pop(context); // Close dialog
        },
      ),
      ElevatedButton(
        child: Text('Done'),
        onPressed: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Back to previous screen
        },
      ),
    ],
  ),
);
} catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save booking. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _fileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = widget.clinic.servicesWithTime.entries
        .where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Book: ${widget.clinic.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _showUserForm
            ? _buildUserInfoForm()
            : _buildServiceSelection(filteredServices),
      ),
    );
  }

Widget _buildServiceSelection(List<MapEntry<String, String>> services) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        decoration: InputDecoration(
          labelText: 'Search service',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
      SizedBox(height: 12),
      Expanded(
        child: ListView.builder(
          itemCount: services.length,
          itemBuilder: (_, i) {
            final service = services[i];
            final isSelected = _selectedService == service.key;

            return Card(
              color: isSelected ? Colors.teal[50] : Colors.white,
              child: ListTile(
                leading: Icon(Icons.medical_services, color: Colors.teal),
                title: Text(service.key),
                subtitle: Text(service.value),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: Colors.teal)
                    : null,
                onTap: () => setState(() => _selectedService = service.key),
              ),
            );
          },
        ),
      ),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.date_range),
              label: Text(_selectedDate == null
                  ? 'Pick Date'
                  : _selectedDate!.toLocal().toString().split(' ')[0]),
              onPressed: _pickDate,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.access_time),
              label: Text(_selectedTime == null
                  ? 'Pick Time'
                  : _selectedTime!.format(context)),
              onPressed: _pickTime,
            ),
          ),
        ],
      ),
      SizedBox(height: 16),
      ElevatedButton(
        child: Text('Book'),
        onPressed: _onBookPressed,
      ),
    ],
  );
}

Widget _buildUserInfoForm() {
  return Form(
    key: _userFormKey,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(labelText: 'First Name *'),
            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(labelText: 'Last Name *'),
            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Phone Number *'),
            keyboardType: TextInputType.phone,
            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _idController,
            decoration: InputDecoration(labelText: 'ID Number *'),
            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _fileNumberController,
            decoration: InputDecoration(labelText: 'File Number (Optional)'),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  child: Text('Confirm Booking'),
                  onPressed: _confirmBooking,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

}
