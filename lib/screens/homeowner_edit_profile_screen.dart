import 'package:flutter/material.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/models/homeowner.dart';

class HomeownerEditProfileScreen extends StatefulWidget {
  const HomeownerEditProfileScreen({super.key});

  @override
  State<HomeownerEditProfileScreen> createState() => _HomeownerEditProfileScreenState();
}

class _HomeownerEditProfileScreenState extends State<HomeownerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedDistrict = 'gasabo';

  final Map<String, String> _districtLabels = {
    'gasabo': 'Gasabo',
    'kicukiro': 'Kicukiro',
    'nyarugenge': 'Nyarugenge',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Homeowner Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(),
                ),
                items: _districtLabels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
