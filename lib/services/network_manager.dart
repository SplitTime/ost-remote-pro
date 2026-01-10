import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import 'package:open_split_time_v2/services/preferences_service.dart';

class NetworkManager {
  static const _baseUrl = 'https://www.opensplittime.org/';
  final PreferencesService _prefs = PreferencesService();

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

      // Save token using PreferencesService
      _prefs.token = data['token'];
      _prefs.tokenExpiration = DateTime.parse(data['expiration']);
      _prefs.email = email;

      developer.log(
        'Login successful, token saved.',
        name: 'NetworkManager.login',
      );

      return data;
    } else {
      throw Exception(
          'Login failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<String?> getEventSlugByName(String name) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    try {
      final response = await http.get(
        Uri.parse(
            '${_baseUrl}api/v1/events?filter[editable]=true&filter[name]=$name'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'] is List) {
          for (var event in data['data']) {
            if (event['attributes'] != null &&
                event['attributes']['name'] != null) {
              final eventName = event['attributes']['name'].toString();
              if (eventName == name) {
                return event['attributes']['slug'].toString();
              }
            }
          }
        }
      } else if (response.statusCode == 401) {
        throw Exception(
            '\nAuthentication failed. Please try logging in again.');
      } else {
        throw Exception(
            '\nFailed to load events (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching event ID: $e');
    }
    return null;
  }

  Future<String?> getToken() async {
    return _prefs.token;
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
          if (event['attributes'] != null &&
              event['attributes']['name'] != null) {
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
      throw Exception(
          '\nFailed to load events (${response.statusCode}): ${response.body}');
    }
  }

  Future<Map<int, Map<String, String>>> fetchParticipantNames({
    required String eventName,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${_baseUrl}api/v1/events/$eventName?include=efforts&fields[efforts]=fullName,bibNumber,age,gender,city,stateCode'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['included'] != null && data['included'] is List) {
          final included = data['included'] as List;

          final Map<int, Map<String, String>> effortsMap = {
            for (var effort in included)
              if (effort['attributes'] != null &&
                  effort['attributes']['bibNumber'] != null)
                effort['attributes']['bibNumber'] as int: {
                  'fullName':
                      effort['attributes']['fullName']?.toString() ?? '',
                  'age': effort['attributes']['age']?.toString() ?? '',
                  'gender': effort['attributes']['gender']?.toString() ?? '',
                  'city': effort['attributes']['city']?.toString() ?? '',
                  'stateCode':
                      effort['attributes']['stateCode']?.toString() ?? '',
                },
          };

          developer.log(
            'Fetched ${effortsMap.length} participants',
            name: 'NetworkManager.fetchParticipantNames',
          );
          return effortsMap;
        }
      }
    } catch (e) {
      developer.log('Error fetching participants: $e',
          name: 'NetworkManager.fetchParticipantNames');
    }
    return {};
  }
}
