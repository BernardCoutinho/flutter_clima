import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "SUA_CHAVE_DA_API"; // Insira sua chave aqui

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=pt";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Falha ao obter dados do clima");
    }
  }
}
