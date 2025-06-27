import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'AdminPage.dart';
import 'ClinicListScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String clinicName = '';
  String password = '';
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin(BuildContext context) async {
    setState(() => isLoading = true);

    try {
      if (clinicName.isEmpty) {
        final doc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
        final storedPassword = doc.data()?['password'];

        if (password == storedPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminPage(isSuperAdmin: true)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incorrect admin password')),
          );
        }
      } else {
        final query = await FirebaseFirestore.instance
            .collection('clinics')
            .where('name', isEqualTo: clinicName)
            .where('password', isEqualTo: password)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final clinicId = query.docs.first.id;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPage(isSuperAdmin: false, clinicId: clinicId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid clinic name or password')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Check your connection.')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
void _showLoginDialog() {
  String dialogClinic = '';
  String dialogPassword = '';
  bool dialogLoading = false;
  bool _obscureDialogPassword = true;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text('Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (val) => dialogClinic = val.trim(),
                decoration: InputDecoration(labelText: 'Clinic Name (leave empty for admin)'),
              ),
              SizedBox(height: 12),
              TextField(
                obscureText: _obscureDialogPassword,
                onChanged: (val) => dialogPassword = val,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureDialogPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscureDialogPassword = !_obscureDialogPassword);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              child: dialogLoading
                  ? CircularProgressIndicator(strokeWidth: 2)
                  : Text('Login'),
              onPressed: () async {
                setState(() => dialogLoading = true);
                try {
                  if (dialogClinic.isEmpty) {
                    final doc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
                    final storedPassword = doc.data()?['password'];
                    if (storedPassword == dialogPassword) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => AdminPage(isSuperAdmin: true)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Incorrect admin password')),
                      );
                    }
                  } else {
                    final query = await FirebaseFirestore.instance
                        .collection('clinics')
                        .where('name', isEqualTo: dialogClinic)
                        .where('password', isEqualTo: dialogPassword)
                        .limit(1)
                        .get();

                    if (query.docs.isNotEmpty) {
                      final clinicId = query.docs.first.id;
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminPage(isSuperAdmin: false, clinicId: clinicId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid clinic name or password')),
                      );
                    }
                  }
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login failed. Check your network.')),
                  );
                } finally {
                  setState(() => dialogLoading = false);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // 📱 MOBILE view with admin dialog
      return Scaffold(
        backgroundColor: Colors.teal[50],
        appBar: AppBar(
          title: Text('Clinic Booking'),
          actions: [
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Login',
              onPressed: _showLoginDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  Icon(Icons.local_hospital, size: 100, color: Colors.teal),
                  SizedBox(height: 24),
                  Text(
                    'Welcome to Clinic Booking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Your health, your time.', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.arrow_forward),
                      label: Text('Get Started'),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => ClinicListScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 💻 WEB view with login form
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital, size: 100, color: Colors.teal),
                  SizedBox(height: 24),
                  Text(
                    'Welcome to Clinic Booking',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                  ),
                  SizedBox(height: 12),
                  Text('Your health, your time.', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 32),
                  TextField(
                    onChanged: (val) => clinicName = val.trim(),
                    decoration: InputDecoration(
                      labelText: 'Clinic Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    obscureText: _obscurePassword,
                    onChanged: (val) => password = val,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.login),
                      label: Text('Login'),
                      onPressed: isLoading ? null : () => _handleLogin(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
