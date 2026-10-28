import 'dart:convert';
import "lib/fakeTreinoService.dart";
import "lib/fakeUserService.dart";
import 'package:server/Controllers/TreinosController.dart';
import 'package:server/Controllers/UserController.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('PUT /user', () {
    test('atualiza as configurações do usuário', () async {
      final service = FakeUserService();
      final controller = UserController(service);

      final response = await controller.updateSettings(
        Request(
          'PUT',
          Uri.parse('http://localhost/user'),
          body: jsonEncode({
            'email': 'aluno@example.com',
            'altura': 1.75,
            'peso': 72,
          }),
        ),
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'Configurações executadas');
      expect(service.settings?.email, 'aluno@example.com');
      expect(service.settings?.altura, 1.75);
      expect(service.settings?.peso, 72.0);
    });

    test('retorna 400 quando faltam parâmetros obrigatórios', () async {
      final service = FakeUserService();
      final controller = UserController(service);

      final response = await controller.updateSettings(
        Request(
          'PUT',
          Uri.parse('http://localhost/user'),
          body: jsonEncode({'email': 'aluno@example.com'}),
        ),
      );

      expect(response.statusCode, 400);
      expect(service.settings, isNull);
    });
  });

  group('PUT /treino', () {
    const treinoId = '65f123abc456def789012345';

    test('atualiza o treino com os exercícios informados', () async {
      final service = FakeTreinoService();
      final controller = Treinoscontroller(service);

      final response = await controller.updateTreino(
        Request(
          'PUT',
          Uri.parse('http://localhost/treino?TreinoId=$treinoId'),
          body: jsonEncode({
            'nomeTreino': 'Treino A',
            'exercicios': [
              {'nome': 'Supino', 'repeticoes': 10, 'intervalo': 60},
            ],
          }),
        ),
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), contains('Treino A'));
      expect(service.updatedId, treinoId);
      expect(service.updatedTreino?.nome, 'Treino A');
      expect(service.updatedTreino?.userId, service.userId);
      expect(service.updatedTreino?.itemTreino, hasLength(1));
      expect(service.updatedTreino?.itemTreino.single.exercicio.nome, 'Supino');
      expect(service.updatedTreino?.itemTreino.single.repeticoes, 10);
      expect(service.updatedTreino?.itemTreino.single.intervalo, 60);
    });

    test('retorna 400 quando o identificador do treino está ausente', () async {
      final service = FakeTreinoService();
      final controller = Treinoscontroller(service);

      final response = await controller.updateTreino(
        Request(
          'PUT',
          Uri.parse('http://localhost/treino'),
          body: jsonEncode({'nomeTreino': 'Treino A', 'exercicios': []}),
        ),
      );

      expect(response.statusCode, 400);
      expect(service.updatedTreino, isNull);
    });
  });
}
