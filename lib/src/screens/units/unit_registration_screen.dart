import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/unit_controller.dart';
import 'package:sample/src/util/snack.dart';

class UnitRegistrationScreen extends StatefulWidget {
  const UnitRegistrationScreen({super.key});

  @override
  State<UnitRegistrationScreen> createState() => _UnitRegistrationScreenState();
}

class _UnitRegistrationScreenState extends State<UnitRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  late UnitController _unitController;
  bool _isSubmitClicked = false;

  @override
  void initState() {
    super.initState();
    _unitController = Provider.of<UnitController>(context, listen: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Unit Registration',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
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
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'Register a New Unit',
                  style:
                      Theme.of(
                        context,
                      ).textTheme.displayMedium, // Use displayMedium
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  label: 'Unit Name*',
                  icon: Icons.shopping_bag,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the unit name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      _isSubmitClicked
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isSubmitClicked = true;
                              });
                              bool isSuccess = await _unitController
                                  .registerUnit(_nameController.text.trim());
                              _isSubmitClicked = false;
                              if (isSuccess) {
                                showSuccessSnack(
                                  "Unit registered successfully!",
                                );
                                Navigator.pop(context, true);
                              } else {
                                showErrorSnack("Error registering product");
                              }

                              // Navigate back
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.blue.shade900,
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
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
