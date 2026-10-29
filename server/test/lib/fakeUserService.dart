import 'package:mongo_dart/mongo_dart.dart';
import 'package:server/Models/UserModel.dart';
import 'package:server/Services/UserService.dart';
import 'package:server/Utilitys/Exceptions.dart';
import 'package:server/data/DAO/UserDAO.dart';

class FakeUserService extends UserService {
  FakeUserService({this.userAlreadyExists = false})
    : super(UserDAO(Db('mongodb://localhost/test')));

  final bool userAlreadyExists;
  UserModel? settings;
  UserModel? registeredUser;
  int registerCalls = 0;
  UserModel? authenticatedUser;
  UserModel? authRequest;
  Exception? authError;
  int authCalls = 0;

  @override
  Future<UserModel> Register(UserModel usuario) async {
    registerCalls++;
    registeredUser = usuario;

    if (userAlreadyExists) throw UserAlreadyExistsException();

    return UserModel.registerReponse(nome: usuario.nome, email: usuario.email);
  }

  @override
  Future<UserModel> Auth(UserModel userRequest) async {
    authCalls++;
    authRequest = userRequest;

    if (authError != null) throw authError!;
    if (authenticatedUser == null) {
      throw StateError('No authenticated user configured in fake service');
    }

    return authenticatedUser!;
  }

  @override
  Future<void> UpdateSettings(UserModel settings) async {
    this.settings = settings;
  }
}
