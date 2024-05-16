import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/View/help_screen.dart';
import '../Model/weather_model.dart';
import '../Services/api_services.dart';
import 'package:geolocator/geolocator.dart';

import '../main.dart';

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

  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    locationName = sharedPrefs.getString('locationName') ?? '';
    _textEditingController = TextEditingController(text: locationName);
    _getWeatherData(locationName);
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
        message = "Failed to get weather info for \n$location";
        response = null;
      });
    } finally {
      setState(() {
        inProgress = false;
      });
    }
  }

  _saveLocation(String location) {
    sharedPrefs.setString('locationName', location);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // for top bar
          topBar(context),
          Expanded(
            child: Stack(
              children: [
                // for button blue container
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.lightBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    height: size.height / 2.2,
                  ),
                ),
                // for weathe data container
                Positioned(
                  bottom: 100,
                  right: 30,
                  left: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.white,
                            Color.fromARGB(255, 133, 208, 243),
                          ]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    height: size.height,
                    child: Center(
                      child: ListView(
                        children: [
                          SizedBox(
                            height: size.height * 0.25,
                          ),
                          buildSearch(),
                          const SizedBox(height: 40),
                          if (inProgress)
                            const Center(child: CircularProgressIndicator())
                          else
                            buildWeatherData(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SafeArea topBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(9)),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                  color: Colors.blue[200],
                  borderRadius: BorderRadius.circular(9)),
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.menu,
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildSearch() {
    return Column(
      children: [
        SearchBar(
          elevation: const MaterialStatePropertyAll(1.2),
          backgroundColor: const MaterialStatePropertyAll(Colors.white),
          trailing: const [
            Icon(Icons.search),
            SizedBox(
              width: 10,
            )
          ],
          hintText: "Search any location",
          controller: _textEditingController,
          onChanged: (value) {
            setState(() {
              locationName = value;
              isLocationEmpty = value.isEmpty;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[200]),
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildWeatherData() {
    String formattedDate =
        DateFormat('EEEE d, MMMM yyy').format(DateTime.now());
    if (response == null) {
      return Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      );
    } else {
      return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 32,
                  color: Colors.blue,
                ),
                Text(
                  response!.location?.name ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  response!.location?.country ?? "",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: SizedBox(
              height: 200,
              child: Image.network(
                "https:${response!.current?.condition?.icon}"
                    .replaceAll("128x64", "128x128"),
                scale: 0.1,
              ),
            ),
          ),
          Text(
            "${response!.current?.tempC.toString() ?? ""} °c",
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            (response!.current?.condition?.text.toString() ?? ""),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }
}
