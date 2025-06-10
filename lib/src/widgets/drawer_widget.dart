import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/main.dart';
import 'package:sample/src/models/user_model.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

import '../repo/auth_repo.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF818CF8);

  final AuthController _authController = AuthController();
  UserData? _currentUser;
  final bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false);
    });
    _authController.addListener(_updateUser);
  }

  @override
  void dispose() {
    _authController.removeListener(_updateUser);
    super.dispose();
  }

  void _updateUser() {
    if (mounted) {
      setState(() {
        _currentUser = _authController.userData;
        print('User data updated: $_currentUser');
      });
    }
  }

  void _logout() async {
    // Show a confirmation dialog before logging out
    bool confirmLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Logout'),
              content: Text('Are you sure you want to Logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    bool isSuccess = await _authController.logout(
                      AuthRepo.loginId,
                    );
                    if (isSuccess) {
                      showSuccessSnack("Logged out successfully!");
                      Navigator.pop(context, true);
                    } else {
                      showErrorSnack("Error logging out");
                    }

                    // Navigate back
                  },
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmLogout) {
      NavigationService().pushAndRemoveUntilNavigation(Screenroutes.login);
      Future.delayed(Duration(milliseconds: 500), () {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('User Logged out successfully!'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      });
    }
  }

  Widget _buildProfileImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Hero(
        tag: 'profile-image',
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(imageUrl),

              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      // Default avatar when no image is available
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.person, size: 30, color: primaryColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final imageUrl = authController.userData?.imageUrl;
        return Drawer(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, secondaryColor],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                InkWell(
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.profileUpdateScreen,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        // User Avatar - With actual profile image
                        _buildProfileImage(imageUrl),
                        const SizedBox(width: 16),
                        // User Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // _isLoading
                                //     ? 'Loading...'
                                //     :
                                'Hi ${AuthRepo.user ?? 'User'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Show contact number if available
                              if (_currentUser?.role_id != null && !_isLoading)
                                Text(
                                  _currentUser!.role_id!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              SizedBox(height: 4),
                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
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
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit profile icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Decorative Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 5), // Reduced spacing
                // Menu Items - More compact
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                // New menu item for Profile Update
                _buildMenuItem(
                  context: context,
                  icon: Icons.person,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    NavigationService().pushNavigation(
                      Screenroutes.profileUpdateScreen,
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.contact_page,
                  title: 'Contacts',
                  onTap: () {
                    Navigator.pop(context);
                    NavigationService().pushNavigation(
                      Screenroutes.contactsScreen,
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.shopping_bag,
                  title: 'Purchases',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.purchaseListScreen,
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.shop,
                  title: 'Sales',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.salesListScreen,
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.money,
                  title: 'Expenses',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.expenseListScreen,
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.monetization_on,
                  title: 'Financial Transactions',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.financialTransactions,
                    );
                  },
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.dataset_rounded,
                  title: 'Master',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.masterScreen,
                    );
                  },
                ),

                _buildMenuItem(
                  context: context,
                  icon: Icons.lock_reset,
                  title: 'Change Password',
                  onTap: () {
                    NavigationService().pushNavigation(
                      Screenroutes.changePassword,
                    );
                  },
                ),
                // Added height to push logout to bottom
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: Colors.white.withOpacity(0.2),
                    thickness: 1,
                  ),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isLogout: true,
                  onTap: () {
                    _logout();
                  },
                ),
                const SizedBox(height: 16), // Reduced padding at bottom
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 3,
      ), // Reduced vertical margin
      decoration: BoxDecoration(
        color:
            isLogout
                ? Colors.red.withOpacity(0.1)
                : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), // Slightly smaller radius
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8), // Smaller padding
          decoration: BoxDecoration(
            color:
                isLogout
                    ? Colors.red.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20, // Smaller icon
            color: isLogout ? Colors.red[100] : Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red[100] : Colors.white,
            fontSize: 14, // Smaller font
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ), // Reduced padding
      ),
    );
  }
}
