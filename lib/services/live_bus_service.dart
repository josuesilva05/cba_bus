import 'dart:convert';
import 'package:http/http.dart' as http;

class LiveBusService {
  final String apiUrl = "http://144.22.240.151:3000/api/pontos/linhasapp";

  Future<List<Map<String, String>>> fetchBusLines() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        return data.map((item) {
          String nomeLinha = item["nome_linha"] ?? "Desconhecido";
          String id = item["id"] ?? ""; // Garante que o ID não seja nulo

          List<String> partes = nomeLinha.split(" - ");
          String numero = partes.isNotEmpty ? partes[0] : "Desconhecido";
          String descricao =
              partes.length > 1
                  ? partes.sublist(1).join(" - ")
                  : "Sem descrição";

          return {
            "id": id, // Adicionando o ID para navegação
            "numero": numero,
            "descricao": descricao,
          };
        }).toList();
      } else {
        throw Exception("Erro ao carregar os dados");
      }
    } catch (e) {
      print("Erro na API: $e");
      return [];
    }
  }
}
