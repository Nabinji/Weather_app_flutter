import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/View/help_screen.dart';
import '../Model/weather_model.dart';
import '../Services/api_services.dart';
import 'package:geolocator/geolocator.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Homepage> {
  ApiResponse? response;
  bool inProgress = false;
  String message = "";
  String locationName = '';
  bool isLocationEmpty = true;

  late SharedPreferences _prefs;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _getWeatherData('');
  }

  _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      locationName = _prefs.getString('locationName') ?? '';
      _textEditingController = TextEditingController(text: locationName);
    });
  }

  _getWeatherData(String location) async {
    setState(() {
      inProgress = true;
    });

    try {
      if (location.isEmpty) {
        Position position = await LocationService().getLocation();
        response = await WeatherApi()
            .getCurrentWeatherByLatLong(position.latitude, position.longitude);
      } else {
        response = await WeatherApi().getWeather(location);
      }
    } catch (e) {
      setState(() {
        message = "Failed to get weather info for $location";
        response = null;
      });
    } finally {
      setState(() {
        inProgress = false;
      });
    }
  }

  _saveLocation(String location) {
    _prefs.setString('locationName', location);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpScreen()));
                },
                child: const Icon(Icons.arrow_back_ios),
              ),
              buildSearch(),
              const SizedBox(height: 20),
              if (inProgress)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: buildWeatherData(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearch() {
    return Row(
      children: [
        Expanded(
          child: SearchBar(
            hintText: "Search any location",
            controller: _textEditingController,
            onChanged: (value) {
              setState(() {
                locationName = value;
                isLocationEmpty = value.isEmpty;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              if (!isLocationEmpty) {
                _saveLocation(locationName);
                _getWeatherData(locationName);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                isLocationEmpty ? "Save" : "Update",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildWeatherData() {
    if (response == null) {
      return Text(message);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.location_on,
                size: 40,
                color: Colors.blue,
              ),
              Text(
                response!.location?.name ?? "",
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Expanded(
                child: Text(
                  response!.location?.country ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "${response!.current?.tempC.toString() ?? ""} °c",
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  (response!.current?.condition?.text.toString() ?? ""),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: SizedBox(
              height: 200,
              child: Image.network(
                "https:${response!.current?.condition?.icon}"
                    .replaceAll("64x64", "128x128"),
                scale: 0.7,
              ),
            ),
          ),
        ],
      );
    }
  }
}

class SearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBar({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            suffixIcon: const Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}
