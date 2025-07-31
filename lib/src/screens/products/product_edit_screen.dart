import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/product_controller.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditProductScreen({super.key, required this.data});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedImages = [];
  List<String> _existingImages = [];
  bool _isLoading = false;
  late ProductController _productController;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _productController = Provider.of<ProductController>(context, listen: false);
    // Get product name from data - matching your product list structure
    String? productName =
        widget.data['Name'] ??
        widget.data['name'] ??
        widget.data['productName'] ??
        widget.data['product_name'] ??
        widget.data['title'];

    _nameController.text = productName ?? '';

    // Get images from data - handle both single image and multiple images
    List<String> imagesList = [];

    // Handle single image field (as seen in your product list)
    if (widget.data['image'] != null &&
        widget.data['image'].toString().isNotEmpty) {
      imagesList.add(widget.data['image'].toString());
    }

    // Handle multiple images array
    if (widget.data['images'] != null) {
      try {
        List<String> additionalImages = List<String>.from(
          widget.data['images'],
        );
        imagesList.addAll(additionalImages);
      } catch (e) {
        print('Error parsing images array: $e');
      }
    }

    // Handle other possible image field names
    if (widget.data['imageUrls'] != null) {
      try {
        List<String> additionalImages = List<String>.from(
          widget.data['imageUrls'],
        );
        imagesList.addAll(additionalImages);
      } catch (e) {
        print('Error parsing imageUrls array: $e');
      }
    }

    _existingImages = imagesList;

    // Debug print to verify data loading
    print('Initializing product data:');
    print('Product Name: $productName');
    print('Product Images: $_existingImages');
    print('Full product data: ${widget.data}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to take picture: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert selected images to MultipartFile
      List<MultipartFile>? files;
      if (_selectedImages.isNotEmpty) {
        files = [];
        for (File image in _selectedImages) {
          files.add(
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last,
            ),
          );
        }
      }

      // Call your controller method with product ID from data
      int? productId =
          widget.data['id'] ??
          widget.data['productId'] ??
          widget.data['product_id'];

      final success = await _productController.updateProduct(
        productId,
        _nameController.text.trim(),
        files,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to update product. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error updating product: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Product updated successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(
                    context,
                    true,
                  ); // Return to previous screen with success
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildImageGrid() {
    final allImages = <Widget>[];

    // Add existing images
    for (int i = 0; i < _existingImages.length; i++) {
      allImages.add(_buildExistingImageCard(_existingImages[i], i));
    }

    // Add new selected images
    for (int i = 0; i < _selectedImages.length; i++) {
      allImages.add(_buildNewImageCard(_selectedImages[i], i));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: allImages,
    );
  }

  Widget _buildExistingImageCard(String imageUrl, int index) {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeExistingImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageCard(File image, int index) {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          // Badge to indicate new image
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name Field
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter product name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Product name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Product name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Images Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Images',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Add Images'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_existingImages.isEmpty && _selectedImages.isEmpty)
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No images selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildImageGrid(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Update Product',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
