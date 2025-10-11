import 'package:sample/src/providers/base_controller.dart';

import '../data/rest_client.dart';

class DashboardController extends BaseController {
  bool isLoading = false;
  String? errorMessage;
  int? id;
  Map<String, dynamic>? cashOnHand;
  Map<String, dynamic>? amountInBank;
  Map<String, dynamic>? investorPayable;
  List<Map<String, dynamic>>? allBankAccounts;

  Future<void> getInvestorBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final adminDashboardData = await restApi.getAdminDashboardData(
        token: getAuthHeader(),
      );

      if (adminDashboardData['IsSuccess'] == true) {
        cashOnHand = Map<String, dynamic>.from(
          adminDashboardData['Data']['cash_on_hand'],
        );
        amountInBank = Map<String, dynamic>.from(
          adminDashboardData['Data']['amount_in_bank'],
        );
        investorPayable = Map<String, dynamic>.from(
          adminDashboardData['Data']['investor_payable'],
        );
        allBankAccounts = List<Map<String, dynamic>>.from(
          adminDashboardData['Data']['all_bank_accounts'],
        );
      } else {
        errorMessage =
            adminDashboardData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
