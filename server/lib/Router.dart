import 'package:server/Controllers/UserController.dart';
import 'package:server/Controllers/TreinosController.dart';
import 'package:server/Controllers/ExercicioController.dart';
import 'package:server/Utilitys/Middlewares.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Endpoint {
  final Exerciciocontroller exercicioctrl;
  final UserController userctrl;
  final Treinoscontroller treinoctrl;
  Endpoint({
    required this.exercicioctrl,
    required this.userctrl,
    required this.treinoctrl,
  });

  Handler get handler {
    Router roteadorPrincipal = Router();

    roteadorPrincipal.post("/user/register", userctrl.Register);
    roteadorPrincipal.post("/user/auth", userctrl.Auth);

    Router roteadorPrivado = Router();

    roteadorPrivado.post("/treino", treinoctrl.insertTreino);

    roteadorPrivado.get("/getexercicios", exercicioctrl.listexercicios);

    roteadorPrivado.get('/treino', treinoctrl.listTreinos);

    roteadorPrivado.put("/user", userctrl.updateSettings);

    roteadorPrivado.put("/treino", treinoctrl.updateTreino);

    roteadorPrivado.delete("/treino", treinoctrl.deleteTreino);

    Handler pipePrivat = Pipeline()
        .addMiddleware(verifyJWT())
        .addHandler(roteadorPrivado.call);

    roteadorPrincipal.mount('/api', pipePrivat);

    //Endpoint retornando todos os exercicios ou filtrando com base em um search de pesquisa

    return roteadorPrincipal.call;
  }
}
