import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  // OpenStreetMap Nominatim API (FREE, no API key needed)
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  static Future<Position?> getCurrentPosition() async {
    try {
      print('📍 Checking location permissions...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('📍 New permission status: $permission');

        if (permission == LocationPermission.denied) {
          print('📍 Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('📍 Location permissions are permanently denied');
        return null;
      }

      print('📍 Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      print(
          '📍 Position acquired: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Location error: $e');
      return null;
    }
  }

  static Future<String> getAddressFromCoordinates(
      double lat, double lng) async {
    try {
      print('📍 Getting address for: $lat, $lng');

      final response = await http.get(
        Uri.parse(
            '$_nominatimBaseUrl/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
        headers: {
          'User-Agent': 'ShoppingListApp/1.0',
          'Accept-Language': 'id',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        // Build address string from most specific to general
        String addressString = '';

        // Start with specific location
        if (address['road'] != null) {
          addressString = address['road'];
        } else if (address['neighbourhood'] != null) {
          addressString = address['neighbourhood'];
        } else if (address['suburb'] != null) {
          addressString = address['suburb'];
        }

        // Add city/town
        if (address['village'] != null) {
          if (addressString.isNotEmpty) addressString += ', ';
          addressString += address['village'];
        } else if (address['town'] != null) {
          if (addressString.isNotEmpty) addressString += ', ';
          addressString += address['town'];
        } else if (address['city'] != null) {
          if (addressString.isNotEmpty) addressString += ', ';
          addressString += address['city'];
        } else if (address['county'] != null) {
          if (addressString.isNotEmpty) addressString += ', ';
          addressString += address['county'];
        }

        // Add state/province if available
        if (address['state'] != null && addressString.isNotEmpty) {
          addressString += ', ${address['state']}';
        }

        // Add country
        if (address['country'] != null && addressString.isNotEmpty) {
          addressString += ', ${address['country']}';
        }

        if (addressString.isEmpty) {
          // Fallback jika tidak ada data alamat yang valid
          addressString =
              'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        }

        print('📍 Address found: $addressString');
        return addressString;
      }

      // Fallback jika API gagal
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }
  }

  static Future<String> getPlaceName(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_nominatimBaseUrl/reverse?format=json&lat=$lat&lon=$lng&zoom=16&addressdetails=1'),
        headers: {
          'User-Agent': 'ShoppingListApp/1.0',
          'Accept-Language': 'id',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        // Prioritize more specific place names
        if (address['neighbourhood'] != null) {
          return address['neighbourhood'];
        } else if (address['suburb'] != null) {
          return address['suburb'];
        } else if (address['village'] != null) {
          return address['village'];
        } else if (address['town'] != null) {
          return address['town'];
        } else if (address['city'] != null) {
          return address['city'];
        } else if (address['county'] != null) {
          return address['county'];
        } else if (address['state'] != null) {
          return address['state'];
        }
      }

      return 'Lokasi Anda';
    } catch (e) {
      print('❌ Place name error: $e');
      return 'Lokasi Anda';
    }
  }

  // ✅ SIMPLIFIED VERSION - Tanpa mock location
  static Map<String, dynamic> getMockLocationData() {
    return {
      'latitude': -6.2088,
      'longitude': 106.8456,
      'address': 'Jl. MH Thamrin, Jakarta Pusat, DKI Jakarta, Indonesia',
    };
  }

  static Future<double> calculateDistance(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      double distance = Geolocator.distanceBetween(
        startLat,
        startLng,
        endLat,
        endLng,
      );
      return distance / 1000; // Convert to kilometers
    } catch (e) {
      print('❌ Distance calculation error: $e');
      return 0.0;
    }
  }

  static Future<Position?> getLastKnownPosition() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        print(
            '📍 Last known position: ${position.latitude}, ${position.longitude}');
      }
      return position;
    } catch (e) {
      print('❌ Last known position error: $e');
      return null;
    }
  }

  // ✅ HELPER METHOD untuk mendapatkan lokasi dengan fallback
  static Future<Map<String, dynamic>> getLocationWithFallback() async {
    try {
      Position? position = await getCurrentPosition();

      if (position != null) {
        // Get address first
        String address = await getAddressFromCoordinates(
            position.latitude, position.longitude);

        // Get place name for weather data
        String placeName =
            await getPlaceName(position.latitude, position.longitude);

        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address,
          'place_name': placeName,
          'isMock': false,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        // Fallback ke mock data
        print('⚠️ Using mock location data as fallback');
        final mockData = getMockLocationData();
        return {
          ...mockData,
          'place_name': 'Jakarta Pusat',
          'isMock': true,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      final mockData = getMockLocationData();
      return {
        ...mockData,
        'place_name': 'Jakarta Pusat',
        'isMock': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
