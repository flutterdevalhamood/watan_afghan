import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/unit_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool isDeleteSuccess = false;
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;
  late UnitController _unitListController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollController();
      _unitListController = Provider.of<UnitController>(context, listen: false);
      _searchController.text = '';
      _searchQuery = '';
      _unitListController.refresh();
      _unitListController.getUnitData().then((_) {
        setState(() {
          _isInitialLoad = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        if (!_unitListController.isLoading && _unitListController.hasMore) {
          _unitListController.loadMore();
          showInfoSnack('Loading...');
        }
      }
    });
  }

  void _deleteUnit(int index) {
    final unitId = _unitListController.unitData?[index]['id'];
    print('productId $unitId');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Unit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Are you sure you want to delete this unit?"),

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
                  if (unitId != null) {
                    await _unitListController.deleteUnit(unitId, reason);
                  }
                  Navigator.pop(context);
                  showSuccessSnack("Unit Deleted successfully");
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

  // Debounce search logic
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<UnitController>();
    final units =
        watch.unitData != null
            ? (watch.unitData ?? [])
                .where(
                  (unit) => (unit['Name'] ?? '').toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList()
            : [];
    return Consumer<UnitController>(
      builder: (context, unitController, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Units List',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
          ),

          body:
              watch.isLoading && _isInitialLoad
                  ? Center(child: CircularProgressIndicator())
                  : watch.unitData != null
                  ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _unitListController.refresh();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: units.length + 1, // +1 for search box
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // First item = Search Box
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by name...',
                                  hintStyle: TextStyle(
                                    color: Appcolors.textLightGrayColor(
                                      context,
                                    ),
                                  ),
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            );
                          }

                          final unit = units[index - 1];
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.person, size: 30),
                                title: Text(
                                  unit['Name'] ?? '',
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    NavigationService().pushNavigation(
                                      Screenroutes.unitEdit,
                                      arguments: unit,
                                    );
                                  },
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Divider(
                                  color: Colors.grey,
                                  thickness: .5,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                  : SizedBox.shrink(),

          floatingActionButton: FloatingActionButton(
            onPressed: () {
              NavigationService().pushNavigation(Screenroutes.unitRegistration);
              _searchController.clear();
              _searchQuery = '';
              _unitListController.refresh();
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => UnitRegistrationScreen(),
              //   ),
              // );
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
