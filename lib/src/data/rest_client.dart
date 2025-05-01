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

  @POST('/Login')
  Future<UserModel> login({
    @Field("email") String? email,
    @Field("password") String? password,
  });
}
