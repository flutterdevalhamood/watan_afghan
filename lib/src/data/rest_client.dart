import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sample/src/constants/api_constants.dart';
import 'package:sample/src/models/user_model.dart';

part 'rest_client.g.dart';

var dio = Dio();
var restApi = RestClient(dio, baseUrl: apiEndPoint);

@RestApi(baseUrl: apiEndPoint)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST('/api/Login')
  Future<UserModel> login({
    @Field("email") String? email,
    @Field("password") String? password,
  });

  @POST('/api/Logout')
  Future<dynamic> logout({
    @Header("Authorization") String? token,
    @Field("id") int? id,
  });

  @POST('/api/UserChangePassword')
  Future<dynamic> changePassword({
    @Header("Authorization") String? token,
    @Field("currentPassword") String? currentPassword,
    @Field("password") String? password,
  });

  @POST('/api/UserUpdate')
  @MultiPart()
  Future<dynamic> userUpdate({
    @Header("Authorization") String? token,
    @Part(name: "name") String? name,
    @Part(name: "contactNumber") String? contactNumber,
    @Part(name: "imageUrl") File? file,
  });

  @GET('/api/InvestorTransaction/paginate/{page}/{limit}')
  Future<dynamic> getInvestorTransaction(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @GET('/api/InvestorTransactionDetail/{id}')
  Future<dynamic> getInvestorTransactionDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/InvestorTransaction')
  @FormUrlEncoded()
  Future<dynamic> postInvestorTransaction({
    @Header("Authorization") String? token,
    @Field("transaction_type") String? transactionType,
    @Field("totalAmount") String? totalAmount,
    @Field("investor_id") int? investorId,
    @Field("payment_type") String? paymentType,
    @Field("bank_id") int? bankId,
    @Field("accountNumber") String? accountNumber,
    @Field("transferDate") String? transferDate,
    @Field("referenceNumber") String? referenceNumber,
    @Field("PersonName") String? personName,
    @Field("Description") String? description,
    @Field("currency_id") String? currencyId,
    @Field("isIncome") String? isIncome,
  });

  @GET('/api/getInvestorTransactionBaseList')
  Future<dynamic> getInvestorTransactionBaseList({
    @Header("Authorization") String? token,
  });

  @POST('/api/InvestorTransactionDelete')
  Future<dynamic> deleteInvestorTransaction({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? description,
  });

  @POST('/api/InvestorTransactionReport')
  Future<dynamic> postInvestorTransactionReport({
    @Header("Authorization") String? token,
    @Field("fromDate") String? fromDate,
    @Field("toDate") String? toDate,
    @Field("investor_id") int? investorId,
    @Field("currency_id") int? currencyId,
  });

  //currencyConversion
  @GET('/api/CurrencyConversion/paginate/{page}/{limit}')
  Future<dynamic> getCurrencyConversion(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/CurrencyConversion')
  @FormUrlEncoded()
  Future<dynamic> postCurrencyConversion({
    @Header("Authorization") String? token,
    @Field("from_payment_type") String? fromPaymentType,
    @Field("from_currency_id") int? fromCurrencyId,
    @Field("from_amount") String? fromAmount,
    @Field("from_bank_id") int? fromBankId,
    @Field("bank_id") int? bankId,
    @Field("to_payment_type") String? toPaymentType,
    @Field("to_currency_id") int? toCurrencyId,
    @Field("to_amount") String? toAmount,
    @Field("to_bank_id") String? toBankId,
    @Field("referenceNumber") String? referenceNumber,
    @Field("transaction_date") String? transactionDate,
    @Field("Description") String? description,
  });

  @GET('/api/getCurrencyConversionBaseList')
  Future<dynamic> getCurrencyConversionBaseList({
    @Header("Authorization") String? token,
  });

  @GET('/api/CurrencyConversionDetail/{id}')
  Future<dynamic> getCurrencyConversionDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/CurrencyConversionDelete')
  Future<dynamic> deleteCurrencyConversion({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? description,
  });

  @GET('/api/GetAdminDashboardData')
  Future<dynamic> getAdminDashboardData({
    @Header("Authorization") String? token,
  });

  //customerregistration
  @GET('/api/Customer/paginate/{page}/{limit}')
  Future<dynamic> getCustomer(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/Customer')
  @FormUrlEncoded()
  Future<dynamic> postCustomerRegistration({
    @Header("Authorization") String? token,
    @Field("Name") String? name,
    @Field("Representative") String? representative,
    @Field("company_type_id") int? companyTypeId,
    @Field("registrationDate") String? registrationDate,
    @Field("payment_type_id") int? paymentTypeId,
    @Field("to_payment_type") String? toPaymentType,
    @Field("openingBalance") int? openingBalance,
    @Field("openingBalanceAsOfDate") String? openingBalanceAsOfDate,
    @Field("Mobile") String? mobile,
    @Field("Phone") String? phone,
    @Field("Email") String? email,
    @Field("Address") String? address,
    @Field("region_id") int? regionId,
    @Field("postCode") String? postCode,
  });

  @GET('/api/CustomerDetail/{id}')
  Future<dynamic> getCustomerDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @GET('/api/getCustomerBaseList')
  Future<dynamic> getCustomerBaseList({@Header("Authorization") String? token});

  @POST('/api/CustomerDelete')
  @FormUrlEncoded()
  Future<dynamic> deleteCustomer({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? description,
  });

  //supplier
  @GET('/api/Supplier/paginate/{page}/{limit}')
  Future<dynamic> getSupplier(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/Supplier')
  @FormUrlEncoded()
  Future<dynamic> postSupplierRegistration({
    @Header("Authorization") String? token,
    @Field("Name") String? name,
    @Field("Representative") String? representative,
    @Field("company_type_id") int? companyTypeId,
    @Field("registrationDate") String? registrationDate,
    @Field("payment_type_id") int? paymentTypeId,
    @Field("to_payment_type") String? toPaymentType,
    @Field("openingBalance") int? openingBalance,
    @Field("openingBalanceAsOfDate") String? openingBalanceAsOfDate,
    @Field("Mobile") String? mobile,
    @Field("Phone") String? phone,
    @Field("Email") String? email,
    @Field("Address") String? address,
    @Field("region_id") int? regionId,
    @Field("postCode") String? postCode,
  });

  @GET('/api/SupplierDetail/{id}')
  Future<dynamic> getSupplierDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @GET('/api/getSupplierBaseList')
  Future<dynamic> getSupplierBaseList({@Header("Authorization") String? token});

  @POST('/api/SupplierDelete')
  @FormUrlEncoded()
  Future<dynamic> deleteSupplier({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? description,
  });

  //expenses
  @GET('/api/Expense/paginate/{page}/{limit}')
  Future<dynamic> getExpense(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/Expense')
  @FormUrlEncoded()
  Future<dynamic> postExpenseRegistration({
    @Header("Authorization") String? token,
    @Field("supplier_id") int? supplierId,
    @Field("employee_id") int? employeeId,
    @Field("expenseDate") String? expenseDate,
    @Field("referenceNumber") String? referenceNumber,
    @Field("currency_id") int? currencyId,
    @Field("Total") String? total,
    @Field("subTotal") String? subTotal,
    @Field("totalVat") String? totalVat,
    @Field("grandTotal") String? grandTotal,
    @Field("expense_detail") String? expenseDetail,
    @Field("payment_type") String? paymentType,
    @Field("bank_id") int? bankId,
    @Field("transferDate") String? transferDate,
    @Field("ChequeNumber") String? chequeNumber,
  });

  @GET('/api/ExpenseDetail/{id}')
  Future<dynamic> getExpenseDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @GET('/api/getExpenseBaseList')
  Future<dynamic> getExpenseBaseList({@Header("Authorization") String? token});

  @POST('/api/ExpenseDelete')
  @FormUrlEncoded()
  Future<dynamic> deleteExpense({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? description,
  });

  @POST('/api/CheckExpenseReferenceExist')
  @FormUrlEncoded()
  Future<dynamic> checkExpenseReferenceExist({
    @Header("Authorization") String? token,
    @Field("referenceNumber") String? referenceNumber,
    @Field("supplier_id") String? supplierId,
  });

  @POST('/api/ExpenseDocumentsUpload')
  Future<dynamic> postExpenseDocumentsUpload({
    @Header("Authorization") String? token,
    @Part(name: "id") int? id,
    @Part(name: 'document[]') List<MultipartFile>? files,
  });

  @GET('/api/Product/paginate/{page}/{limit}')
  Future<dynamic> getProductData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/Product')
  Future<dynamic> registerProduct({
    @Header("Authorization") String? token,
    @Part(name: "Name") String? name,
    @Part(name: 'image') List<MultipartFile>? files,
  });

  @POST('/api/ProductUpdate')
  Future<dynamic> updateProduct({
    @Header("Authorization") String? token,
    @Part(name: "id") int? id,
    @Part(name: "Name") String? name,
    @Part(name: "image") List<MultipartFile>? files,
  });

  @POST('/api/ProductDelete')
  Future<dynamic> deleteProduct({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/api/Unit/paginate/{page}/{limit}')
  Future<dynamic> getUnitData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/Unit')
  Future<dynamic> registerUnit({
    @Header("Authorization") String? token,
    @Field("Name") String? name,
  });

  @POST('/api/UnitUpdate')
  Future<dynamic> updateUnit({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("Name") String? name,
  });

  @POST('/api/UnitDelete')
  Future<dynamic> deleteUnit({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/api/Purchase/paginate/{page}/{limit}')
  Future<dynamic> getPurchaseData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/Purchase')
  Future<dynamic> registerPurchase({
    @Header("Authorization") String? token,
    @Field("supplier_id") int? supplierId,
    @Field("currency_id") int? currencyId,
    @Field("purchase_date") String? purchaseDate,
    @Field("InvoiceNumber") String? invoiceNumber,
    @Field("final_total_before_tax") String? finalTotalBeforeTax,
    @Field("total_tax") String? totalTax,
    @Field("grand_total") String? grandTotal,
    @Field("CustomerNote") String? customerNote,
    @Field("product_details") String? productDetails,
  });

  @GET('/api/getPurchaseBaseList')
  Future<dynamic> getPurchaseBaseList({@Header("Authorization") String? token});

  @GET('/api/PurchaseDetail/{id}')
  Future<dynamic> getPurchaseDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/PurchaseDelete')
  Future<dynamic> deletePurchase({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/api/Sales/paginate/{page}/{limit}')
  Future<dynamic> getSalesData(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @POST('/api/Sales')
  Future<dynamic> registerSales({
    @Header("Authorization") String? token,
    @Field("customer_id") int? customerId,
    @Field("currency_id") int? currencyId,
    @Field("sale_date") String? saleDate,
    @Field("InvoiceNumber") String? invoiceNumber,
    @Field("final_total_before_tax") String? finalTotalBeforeTax,
    @Field("total_tax") String? totalTax,
    @Field("grand_total") String? grandTotal,
    @Field("CustomerNote") String? customerNote,
    @Field("product_details") String? productDetails,
  });

  @GET('/api/getSalesBaseList')
  Future<dynamic> getSalesBaseList({@Header("Authorization") String? token});

  @GET('/api/SaleDetail/{id}')
  Future<dynamic> getSalesDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/SaleDelete')
  Future<dynamic> deleteSales({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? deleteDescription,
  });

  @GET('/api/getAllInvoicesOfProductFromInventory/{id}')
  Future<dynamic> getAllInvoicesOfProductFromInventory({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/getAvailableQtyForInvoiceInventory')
  Future<dynamic> postAvailableQtyForInvoiceInventory({
    @Header("Authorization") String? token,
    @Field("from_invoice") String? fromInvoice,
  });

  @POST('/api/CheckSalesInvoiceExist')
  Future<dynamic> postCheckSalesInvoiceExist({
    @Header("Authorization") String? token,
    @Field("InvoiceNumber") String? invoiceNumber,
  });

  @GET('/api/getSalesPDF/{id}')
  Future<dynamic> getSalesPDF({
    @Path("id") String? id,
    @Header("Authorization") String? token,
  });
}
