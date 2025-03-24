class MockWeatherService {
  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    await Future.delayed(Duration(seconds: 1)); // Simula tempo de carregamento
    return {
      "list": [
        {
          "dt": 1710961200, // Timestamp UNIX
          "main": {"temp": 26.5},
          "weather": [
            {"description": "céu limpo", "icon": "01d"}
          ]
        },
        {
          "dt": 1710972000,
          "main": {"temp": 24.3},
          "weather": [
            {"description": "nuvens dispersas", "icon": "03d"}
          ]
        },
        {
          "dt": 1710982800,
          "main": {"temp": 22.0},
          "weather": [
            {"description": "chuva leve", "icon": "10d"}
          ]
        },
      ]
    };
  }
}
