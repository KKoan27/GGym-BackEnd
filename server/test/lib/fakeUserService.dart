import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/UserModel.dart';
import 'package:server/Services/UserService.dart';
import 'package:server/data/DAO/UserDAO.dart';

class FakeUserService extends UserService {
  FakeUserService() : super(UserDAO(Db('mongodb://localhost/test')));

  UserModel? settings;

  @override
  Future<void> UpdateSettings(UserModel settings) async {
    this.settings = settings;
  }
}
