// Product Listing Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/product_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _reasonController = TextEditingController();
  late ProductController _productController;

  @override
  void initState() {
    super.initState();
    _productController = Provider.of<ProductController>(context, listen: false);
    _loadInitialData();
    _setupScrollListener();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productController.getProductData();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _productController.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [_buildSearchSection(), Expanded(child: _buildProductList())],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          NavigationService().pushNavigation(Screenroutes.productRegistration);
        },
        icon: const Icon(Icons.add),
        label: const Text('Create New'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Products',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
    );
  }

  void _deleteProduct(int index) {
    final productId = _productController.productData?[index]['id'];
    print('productId $productId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Product"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Are you sure you want to delete this product?"),

              SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for deletion',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {
                String reason = _reasonController.text.trim();
                if (reason.isNotEmpty) {
                  if (productId != null) {
                    await _productController.deleteProduct(productId, reason);
                  }
                  Navigator.pop(context);
                  showSuccessSnack("Product Deleted successfully");
                } else {
                  showErrorSnack("Please enter a reason for deletion");
                }
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _productController.clearSearch();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[600]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _productController.searchProducts(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Consumer<ProductController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.displayProducts.isEmpty) {
          return _buildLoadingIndicator();
        }

        if (controller.displayProducts.isEmpty && !controller.isLoading) {
          return RefreshIndicator(
            onRefresh: () => controller.getProductData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: _buildEmptyState(),
              ),
            ),
          );
        }

        print(
          'Display products count: ${controller.displayProducts.length}',
        ); // Debug print

        return RefreshIndicator(
          onRefresh: () => controller.getProductData(),
          color: Colors.blue[600],
          backgroundColor: Colors.white,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount:
                controller.displayProducts.length +
                (controller.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.displayProducts.length) {
                return _buildLoadMoreIndicator();
              }
              return _buildProductCard(
                controller.displayProducts[index],
                index,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildProductImage(product['image']),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['Name'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 24),
                    Row(
                      // mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            NavigationService().pushNavigation(
                              Screenroutes.productEdit,
                              arguments: product,
                            );
                          },

                          icon: Icon(Icons.edit, color: Colors.blue),
                        ),

                        // IconButton(
                        //   onPressed: () async {
                        //     _deleteProduct(index);
                        //   },
                        //   icon: Icon(Icons.delete, color: Colors.red),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildPlaceholderImage();
                  },
                )
                : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey[400],
        size: 24,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Consumer<ProductController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Loading more products...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Consumer<ProductController>(
      builder: (context, controller, child) {
        final isSearching = controller.searchQuery.isNotEmpty;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearching ? Icons.search_off : Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'No products found for "${controller.searchQuery}"'
                    : 'No products available',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Try searching with different keywords'
                    : 'Pull down to refresh',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsModal(product),
    );
  }

  Widget _buildProductDetailsModal(Map<String, dynamic> product) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            product['image'] != null &&
                                    product['image'].toString().isNotEmpty
                                ? Image.network(
                                  product['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildLargePlaceholderImage();
                                  },
                                )
                                : _buildLargePlaceholderImage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    product['Name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargePlaceholderImage() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[200],
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey[400],
        size: 48,
      ),
    );
  }
}
