import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/weather_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

String apiKey = "7f0cd0bb3593496482953532241405";

class WeatherApi {
  final String baseUrl = "http://api.weatherapi.com/v1/current.json";

  Future<ApiResponse> getWeather(String location) async {
    String apiUrl;
    if (location.isEmpty) {
      apiUrl = "$baseUrl?key=$apiKey&q=";
    } else {
      apiUrl = "$baseUrl?key=$apiKey&q=$location";
    }
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load weather");
      }
    } catch (e) {
      throw Exception("Failed to load weather");
    }
  }

  Future<ApiResponse> getCurrentWeatherByLatLong(
      double latitude, double longitude) async {
    String apiUrl = "$baseUrl?key=$apiKey&q=$latitude,$longitude";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to load weather");
      }
    } catch (e) {
      throw Exception("Failed to load weather");
    }
  }
}

class LocationService {
  Future<Position> getLocation() async {
    PermissionStatus permission = await Permission.location.request();
   
    if (permission == PermissionStatus.granted) {
      try {
        return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        throw Exception("Failed to get location: $e");
      }
    } else if (permission == PermissionStatus.denied) {
      throw const PermissionDeniedException(
          "Location permission denied by user");
    } else {
      throw Exception("Location permission not granted");
    }
  }
}
