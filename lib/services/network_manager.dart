import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class NetworkManager {
  static const _baseUrl = 'https://www.opensplittime.org/';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}api/v1/auth'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'cache-control': 'no-cache',
      },
      body: {
        'user[email]': email,
        'user[password]': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save token using SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token'] ?? '');

      developer.log(
        'Login successful, token saved.',
        name: 'NetworkManager.login',
      );

      return data;
    } else {
      throw Exception('Login failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<String?> getEventSlugByName(String name) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}api/v1/events?filter[editable]=true&filter[name]=$name'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'] is List) {
          for (var event in data['data']) {
            if (event['attributes'] != null && event['attributes']['name'] != null) {
              final eventName = event['attributes']['name'].toString();
              if (eventName == name) {
                return event['attributes']['slug'].toString();
              }
            }
          }
        }
      } else if (response.statusCode == 401) {
        throw Exception('\nAuthentication failed. Please try logging in again.');
      } else {
        throw Exception('\nFailed to load events (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching event ID: $e');
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, List<String>>> fetchEventDetails() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    final response = await http.get(
      Uri.parse('${_baseUrl}api/v1/events?filter[editable]=true'),
      headers: {
        'Authorization': token,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Build a map of event name -> aid stations
      Map<String, List<String>> eventAidStations = {};
      if (data['data'] != null && data['data'] is List) {
        for (var event in data['data']) {
          if (event['attributes'] != null && event['attributes']['name'] != null) {
            final eventName = event['attributes']['name'].toString();
            final splits = event['attributes']['splitNames'];
            if (splits != null && splits is List) {
              eventAidStations[eventName] = List<String>.from(splits);
            } else {
              eventAidStations[eventName] = [];
            }
          }
        }
      }
      return eventAidStations;
    } else if (response.statusCode == 401) {
      throw Exception('\nAuthentication failed. Please try logging in again.');
    } else {
      throw Exception('\nFailed to load events (${response.statusCode}): ${response.body}');
    }
  }

  Future<Map<int, String>> fetchParticipantNames({
    required String eventName,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}api/v1/events/$eventName?include=efforts&fields[efforts]=fullName,bibNumber'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Ensure 'included' exists and is a list
        if (data['included'] != null && data['included'] is List) {
          final included = data['included'] as List;
          // Extract all efforts' attributes into a Map
          final Map<int, String> effortsMap = {
            for (var effort in included)
              if (effort['attributes'] != null && 
                 effort['attributes']['bibNumber'] != null)
                effort['attributes']['bibNumber'] as int:
                effort['attributes']['fullName']?.toString() ?? ''
          };
          return effortsMap; // e.g. {42: 'Alice Smith', 17: 'Bob Jones'}
        }
      }
      
      // Add debug print for troubleshooting
      // ignore: avoid_print
      print('No participants found or invalid response for event: $eventName');
      return {}; // fallback if not found or response invalid
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching participants: $e');
      return {};
    }
  }

  /// We try a "rich" include query first (efforts + events). If the server
  /// rejects it, we fall back to just efforts.
  Future<Map<String, dynamic>> getEventDetailsRaw({
    required String eventSlug,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final headers = {
      'Authorization': token,
      'Accept': 'application/json',
    };

    // Attempt 1: efforts + events
    final uri1 = Uri.parse(
      '${_baseUrl}api/v1/events/$eventSlug'
      '?include=efforts,events'
      '&fields[efforts]=fullName,bibNumber'
      '&fields[events]=shortName,parameterizedSplitNames',
    );

    final res1 = await http.get(uri1, headers: headers);
    if (res1.statusCode == 200) {
      return jsonDecode(res1.body) as Map<String, dynamic>;
    }

    // Attempt 2: efforts only
    final uri2 = Uri.parse(
      '${_baseUrl}api/v1/events/$eventSlug'
      '?include=efforts'
      '&fields[efforts]=fullName,bibNumber',
    );
    final res2 = await http.get(uri2, headers: headers);
    if (res2.statusCode == 200) {
      return jsonDecode(res2.body) as Map<String, dynamic>;
    }

    if (res2.statusCode == 401 || res1.statusCode == 401) {
      throw Exception('Authentication failed. Please log in again.');
    }

    throw Exception(
      'Failed to load event details for "$eventSlug" '
      '(status ${res2.statusCode}): ${res2.body}',
    );
  }

  
}