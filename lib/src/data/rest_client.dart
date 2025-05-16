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
}
