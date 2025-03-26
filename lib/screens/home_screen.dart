import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';


import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/orientation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final OrientationService _orientationService = OrientationService();

  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  DateTime? lastLoadedDate;

  Map<String, dynamic>? weatherData;
  int currentIndex = 0;
  bool isPointingUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllerFuture = _initializeCamera();
    _loadWeather();

    _orientationService.start();
    _orientationService.pointingUpStream.listen((isUp) {
      if (isUp != isPointingUp) {
        setState(() {
          isPointingUp = isUp;

          if (isUp) {
            final now = DateTime.now();
            print("🕒 Hora atual detectada: ${DateFormat('HH:mm').format(now)}");

            final isNewDay = lastLoadedDate == null ||
                now.day != lastLoadedDate!.day ||
                now.month != lastLoadedDate!.month ||
                now.year != lastLoadedDate!.year;

            if (isNewDay) {
              _loadWeather();
            } else if (weatherData != null) {
              _setInitialForecastIndex();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _orientationService.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    await _cameraController.initialize();
  }

  Future<void> _loadWeather() async {
    try {
      final location = await _locationService.getCurrentLocation();
      final data = await _weatherService.getWeather(
        location.latitude,
        location.longitude,
      );
      setState(() {
        weatherData = data;
        lastLoadedDate = DateTime.now();
        _setInitialForecastIndex();
      });
    } catch (e) {
      print("Erro ao carregar o clima: $e");
    }
  }

  void _setInitialForecastIndex() {
    final now = DateTime.now();
    final nowTimestamp = now.millisecondsSinceEpoch ~/ 1000;
    final list = weatherData!["list"] as List;

    int closestIndex = 0;
    int minDiff = 999999999;

    for (int i = 0; i < list.length; i++) {
      final itemTimestamp = list[i]["dt"] as int;
      final diff = (itemTimestamp - nowTimestamp).abs();

      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }

    currentIndex = closestIndex;
  }

  void _changeForecast(int change) {
    setState(() {
      currentIndex += change;

      final listLength = weatherData?["list"]?.length ?? 1;
      if (currentIndex < 0) currentIndex = 0;
      if (currentIndex >= listLength) currentIndex = listLength - 1;

      final dt = weatherData!["list"][currentIndex]["dt"];
      final date = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
      print("📆 Previsão atual: ${DateFormat('EEEE dd/MM HH:mm', 'pt_BR').format(date)}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: _cameraController.value.aspectRatio,
                        child: CameraPreview(_cameraController),
                      ),
                    ),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (isPointingUp && weatherData != null)
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _changeForecast(1);
                } else if (details.primaryVelocity! > 0) {
                  _changeForecast(-1);
                }
              },
              child: Center(
                child: Builder(
                  builder: (context) {
                    final forecast = weatherData!["list"][currentIndex];
                    final forecastDate = DateTime.fromMillisecondsSinceEpoch(
                      forecast["dt"] * 1000,
                    );
                    final formattedDate = DateFormat('EEEE - dd/MM', 'pt_BR')
                        .format(forecastDate);
                    final formattedHour =
                        DateFormat('HH:mm').format(forecastDate);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          "https://openweathermap.org/img/wn/${forecast["weather"][0]["icon"]}@2x.png",
                          width: 100,
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          formattedHour,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "${forecast["main"]["temp"]}°C",
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            )
          else
            const Center(
              child: Text(
                "📱 Aponte o celular para o céu para ver a previsão!",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
