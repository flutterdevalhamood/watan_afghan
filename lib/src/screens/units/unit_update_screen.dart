import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/unit_controller.dart';
import 'package:sample/src/util/snack.dart';

class UnitUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const UnitUpdateScreen({super.key, required this.data});

  @override
  _UnitUpdateScreenState createState() => _UnitUpdateScreenState();
}

class _UnitUpdateScreenState extends State<UnitUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _unitNameController;
  late UnitController _unitController;
  File? selectedFile;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unitController = Provider.of<UnitController>(context, listen: false);
      _unitController.getUnitData();
    });
    super.initState();
    _unitNameController = TextEditingController(text: widget.data['Name']);
  }

  @override
  void dispose() {
    // Dispose controllers
    _unitNameController.dispose();
    super.dispose();
  }

  Future<void> saveEditedData() async {
    final id = widget.data['id'];
    final unitName = _unitNameController.text.trim();
    print('unitnameee $unitName');

    if (id != null) {
      bool isSuccess = await _unitController.updateUnit(id, unitName);
      if (isSuccess) {
        showSuccessSnack('Unit updated successfully');
        Navigator.pop(context, true);
      } else {
        showErrorSnack('Error updating data');
      }
    } else {
      showErrorSnack("cannot find Driver id");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Unit',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              saveEditedData();
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: _buildTextField(
              controller: _unitNameController,
              label: 'Unit Name',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter unit name';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade900),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade900),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
