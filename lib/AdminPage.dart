import 'package:clinic_booking_app/WelcomeScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'ClinicListScreen.dart';
import 'AddClinicPage.dart';
import 'AdminDashboardPage.dart'; // For per-clinic service editing
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'clinic.dart';

class AdminPage extends StatefulWidget {
  final bool isSuperAdmin;
  final String? clinicId;

  const AdminPage({this.isSuperAdmin = false, this.clinicId, Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  List<Clinic> _adminClinics = [];
  late TabController _tabController;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    final ref = FirebaseFirestore.instance.collection('clinics');
    final snap = widget.isSuperAdmin
        ? await ref.get()
        : await ref.where(FieldPath.documentId, isEqualTo: widget.clinicId).get();

    setState(() {
      _adminClinics = snap.docs.map((d) {
        final m = d.data();
        return Clinic(
          id: d.id,
          name: m['name'] ?? '',
          servicesWithTime: Map<String, String>.from(m['servicesWithTime'] ?? {}),
          rating: (m['rating'] ?? 0).toDouble(),
        );
      }).toList();
    });
  }

  Future<void> exportBookingsToPdf(List<Map<String, dynamic>> bookings) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('Clinic Bookings')),
        ...bookings.map((b) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${b['firstName']} ${b['lastName']} • ${b['clinicName']}'),
                pw.Text('Service: ${b['service']}'),
                pw.Text('Date: ${b['date']} at ${b['time']}'),
                pw.Text('Status: ${b['status']}'),
                pw.Text('Phone: ${b['phone']}'),
                pw.Text('ID: ${b['idNumber']}'),
                if ((b['fileNumber'] as String).isNotEmpty) pw.Text('File #: ${b['fileNumber']}'),
                pw.Divider(),
              ],
            )),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  Widget _buildClinicCard(Clinic c) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${c.servicesWithTime.length} services'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.teal),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AdminDashboardPage(clinic: c))),
        ),
      );

  Stream<QuerySnapshot> _bookingStream() {
    final coll = FirebaseFirestore.instance.collection('bookings');
    return widget.isSuperAdmin
        ? coll.orderBy('date').snapshots()
        : coll.where('clinicId', isEqualTo: widget.clinicId).orderBy('date').snapshots();
  }

  @override
  Widget build(BuildContext context) =>
      kIsWeb ? _buildWebAdmin(context) : _buildMobileAdmin();

  Widget _buildWebAdmin(BuildContext ctx) => Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard - Web'),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Home',
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => WelcomeScreen()));
              },
            ),
          ],
        ),
        body: Row(children: [
          Container(
            width: 250,
            color: Colors.teal[50],
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Admin Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (widget.isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Clinic'),
                  onTap: () => Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) => AddClinicPage(onClinicAdded: (c) {
                            setState(() => _adminClinics.add(c));
                          }))),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.print, size: 20, color: Colors.white),
                label: const Text('Export Bookings', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  shadowColor: Colors.black45,
                ),
                onPressed: () async {
                  final snap = await FirebaseFirestore.instance.collection('bookings').get();
                  final bookings = snap.docs.map((doc) {
                    final m = doc.data() as Map<String, dynamic>;
                    m['date'] = m['date'].toString().split('T')[0];
                    return m;
                  }).toList();
                  await exportBookingsToPdf(bookings);
                },
              ),
            ]),
          ),
          Expanded(
              child: Column(children: [
            TabBar(controller: _tabController, labelColor: Colors.teal, tabs: const [
              Tab(text: 'Clinics'),
              Tab(text: 'Bookings')
            ]),
            Expanded(
                child: TabBarView(controller: _tabController, children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Registered Clinics',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_adminClinics.isEmpty) const Text('No clinics added yet.', style: TextStyle(color: Colors.grey)),
                  ..._adminClinics.map(_buildClinicCard),
                ],
              ),
              _buildBookingSearchAndList(),
            ]))
          ])),
        ]),
      );

  Widget _buildMobileAdmin() => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            bottom: const TabBar(tabs: [Tab(text: 'Clinics'), Tab(text: 'Bookings')]),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'Export Bookings',
                onPressed: () async {
                  final snap = await FirebaseFirestore.instance.collection('bookings').get();
                  final bookings = snap.docs.map((d) {
                    final m = d.data() as Map<String, dynamic>;
                    m['date'] = m['date'].toString().split('T')[0];
                    return m;
                  }).toList();
                  await exportBookingsToPdf(bookings);
                },
              ),
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: 'Home',
                onPressed: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => WelcomeScreen()));
                },
              ),
            ],
          ),
          body: TabBarView(children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_adminClinics.isEmpty) const Text('No clinics added yet.', style: TextStyle(color: Colors.grey)),
                ..._adminClinics.map(_buildClinicCard),
                const SizedBox(height: 20),
                if (widget.isSuperAdmin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Clinic'),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AddClinicPage(onClinicAdded: (c) {
                              setState(() => _adminClinics.add(c));
                            }))),
                  ),
              ],
            ),
            _buildBookingSearchAndList(),
          ]),
        ),
      );

  Widget _buildBookingSearchAndList() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search bookings...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchText = val.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: GroupedBookingList(
              bookingStream: _bookingStream(),
              searchText: _searchText,
            ),
          ),
        ],
      );
}

class GroupedBookingList extends StatelessWidget {
  final Stream<QuerySnapshot> bookingStream;
  final String searchText;
  const GroupedBookingList({required this.bookingStream, this.searchText = '', Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: bookingStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snap.hasData || snap.data!.docs.isEmpty)
          return const Center(child: Text('No bookings yet.', style: TextStyle(color: Colors.grey)));

        final items = snap.data!.docs.map((doc) {
          final m = doc.data() as Map<String, dynamic>;

          // 🔧 Safely extract and format date
          final dateField = m['date'];
          String displayDate = '';
          if (dateField is Timestamp) {
            displayDate = dateField.toDate().toIso8601String().split('T')[0];
          } else if (dateField is String) {
            displayDate = dateField.split('T')[0];
          }

          return {
            'id': doc.id,
            'firstName': m['firstName'] ?? '',
            'lastName': m['lastName'] ?? '',
            'phone': m['phone'] ?? '',
            'idNumber': m['idNumber'] ?? '',
            'fileNumber': m['fileNumber'] ?? '',
            'clinicName': m['clinicName'] ?? '',
            'service': m['service'] ?? '',
            'date': displayDate,
            'time': m['time'] ?? '',
            'status': m['status'] ?? 'pending',
          };
        }).where((b) {
          final full = '${b['firstName']} ${b['lastName']} ${b['clinicName']} ${b['service']} ${b['phone']}';
          return full.toLowerCase().contains(searchText);
        }).toList();

        return GroupedListView<dynamic, String>(
          elements: items,
          groupBy: (b) => b['date'] as String,
          groupSeparatorBuilder: (String date) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          itemBuilder: (ctx, b) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: const Icon(Icons.event_available, color: Colors.teal),
              title: Text('${b['firstName']} ${b['lastName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clinic: ${b['clinicName']}'),
                  Text('Service: ${b['service']}'),
                  Text('Date: ${b['date']}'),
                  Text('Time: ${b['time']}'),
                  Text('Phone: ${b['phone']}'),
                  Text('ID: ${b['idNumber']}'),
                  if ((b['fileNumber'] as String).isNotEmpty)
                    Text('File #: ${b['fileNumber']}'),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (s) => FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(b['id'])
                    .update({'status': s}),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
                  PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                ],
                child: Chip(
                  label: Text((b['status'] as String).toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor:
                      b['status'] == 'completed' ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
          order: GroupedListOrder.ASC,
        );
      },
    );
  }
}


