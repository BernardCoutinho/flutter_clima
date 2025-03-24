import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/mock_weather_service.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final MockWeatherService _mockWeatherService = MockWeatherService();
  
  Map<String, dynamic>? weatherData;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final location = await _locationService.getCurrentLocation();
      final data =
          await _mockWeatherService.getWeather(location.latitude, location.longitude);
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      print("Erro ao carregar o clima: $e");
    }
  }

  void _changeForecast(int change) {
    setState(() {
      currentIndex += change;
      if (currentIndex < 0) currentIndex = 0;
      if (currentIndex >= (weatherData?["list"]?.length ?? 1)) {
        currentIndex = (weatherData?["list"]?.length ?? 1) - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (weatherData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var forecast = weatherData!["list"][currentIndex];
    String time = DateFormat('HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(forecast["dt"] * 1000));
    String iconCode = forecast["weather"][0]["icon"];
    String iconUrl = "https://openweathermap.org/img/wn/$iconCode@2x.png";

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _changeForecast(1);
          } else if (details.primaryVelocity! > 0) {
            _changeForecast(-1);
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(iconUrl, width: 100),
              Text(
                "$time",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                "${forecast["main"]["temp"]}°C",
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
