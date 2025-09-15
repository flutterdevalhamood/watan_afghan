import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/user_model.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF818CF8);

  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  late AuthController _authController;

  // bool _isLoading = true;
  bool _isSaving = false;
  UserData? _user;
  File? _imageFile;
  bool _imageChanged = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authController = Provider.of<AuthController>(context, listen: false);
      _authController.addListener(_onAuthChanged);

      _nameController.text = AuthRepo.user ?? '';
      _contactController.text = AuthRepo.contact ?? '';
    });
  }

  void _onAuthChanged() {
    // called when AuthController.notifyListeners() is invoked
    if (mounted) {
      setState(() {
        // refresh to pick up AuthRepo.imageUrl / other auth changes
        // we keep no heavy logic here; widget build will read AuthRepo.*
      });
    }
  }

  @override
  void dispose() {
    // remove listener to avoid memory leaks
    try {
      _authController.removeListener(_onAuthChanged);
    } catch (_) {}
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      showErrorSnack("Failed to pick image. Please try again.");
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: primaryColor),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                // ListTile(
                //   leading: Icon(Icons.photo_camera, color: primaryColor),
                //   title: Text('Camera'),
                //   onTap: () {
                //     Navigator.of(context).pop();
                //     _pickImage(ImageSource.camera);
                //   },
                // ),
                if ((AuthRepo.imageUrl != null &&
                        AuthRepo.imageUrl!.isNotEmpty) ||
                    _imageFile != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Remove Photo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _imageFile = null;
                        _imageChanged = true;
                        AuthRepo.imageUrl = null; // Clear the stored image URL
                      });
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      bool isSuccess = await _authController.updateUserProfile(
        token: AuthRepo.token ?? "", // 👈 make sure you pass the token
        name: _nameController.text,
        contactNumber: _contactController.text,
        imageFile: _imageFile,
      );

      setState(() {
        _isSaving = false;
      });

      if (isSuccess) {
        AuthRepo.user = _nameController.text;

        showSuccessSnack("Profile updated successfully!");
        setState(() {
          _imageChanged = false;
        });

        // Log out the user after successful profile update
        bool logoutSuccess = await _authController.logout(AuthRepo.loginId);

        if (logoutSuccess) {
          // Navigate to login screen or wherever you want after logout
          NavigationService().pushAndRemoveUntilNavigation(
            Screenroutes.login, // or your login route
            removeUntilPageName: Screenroutes.login,
          );
        } else {
          NavigationService().pushAndRemoveUntilNavigation(
            Screenroutes.login,
            removeUntilPageName: Screenroutes.login,
          );
        }
      } else {
        showErrorSnack("Failed to update profile. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      showErrorSnack("An error occurred. Please try again later.");
    }
  }

  // Future<void> _saveProfile() async {
  //   if (!_formKey.currentState!.validate()) {
  //     return;
  //   }
  //
  //   setState(() {
  //     _isSaving = true;
  //   });
  //
  //   try {
  //     bool isSuccess = await _authController.updateUserProfile(
  //       token: AuthRepo.token ?? "", // 👈 make sure you pass the token
  //       name: _nameController.text,
  //       contactNumber: _contactController.text,
  //       imageFile: _imageFile,
  //     );
  //
  //     setState(() {
  //       _isSaving = false;
  //     });
  //
  //     if (isSuccess) {
  //       AuthRepo.user = _nameController.text;
  //
  //       showSuccessSnack("Profile updated successfully!");
  //       setState(() {
  //         _imageChanged = false;
  //       });
  //     } else {
  //       showErrorSnack("Failed to update profile. Please try again.");
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isSaving = false;
  //     });
  //     showErrorSnack("An error occurred. Please try again later.");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body:
      // _isLoading
      //     ? Center(child: CircularProgressIndicator(color: primaryColor))
      //     :
      SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  Hero(
                    tag: 'profile-image',
                    child: GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                              image:
                                  _imageFile != null
                                      ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                      : AuthRepo.imageUrl != null &&
                                          AuthRepo.imageUrl!.isNotEmpty &&
                                          AuthRepo.imageUrl!.startsWith('http')
                                      ? DecorationImage(
                                        image: NetworkImage(AuthRepo.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                (_imageFile == null &&
                                        (AuthRepo.imageUrl == null ||
                                            AuthRepo.imageUrl!.isEmpty ||
                                            !AuthRepo.imageUrl!.startsWith(
                                              'http',
                                            )))
                                    ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: primaryColor.withOpacity(0.7),
                                    )
                                    : null,
                          ),
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Role badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${AuthRepo.role}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Contact field
                    // Contact field - Updated with validation
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your contact number';
                        }
                        // Remove any non-digit characters for validation
                        String digitsOnly = value.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (digitsOnly.length > 15) {
                          return 'Contact number cannot exceed 15 digits';
                        }
                        if (digitsOnly.length < 7) {
                          return 'Contact number must be at least 7 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isSaving
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
