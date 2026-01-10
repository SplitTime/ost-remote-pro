import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:open_split_time_v2/services/preferences_service.dart';

class NetworkManager {
  static const _baseUrl = 'https://ost-stage.herokuapp.com/';
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
    final token = _prefs.token;
    if (token == null) {
      throw Exception('No authentication token found');
    }
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}api/v1/event_groups?filter[name]=$name'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return data['data'][0]['attributes']['slug'];
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
    final token = _prefs.token;
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}api/v1/event_groups?filter[editable]=true&filter[availableLive]=true'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Build a map of event name -> aid stations
        final Map<String, List<String>> eventAidStations = {};
        
        if (data['data'] != null && data['data'] is List) {
          for (var eventGroup in data['data']) {
            if (eventGroup['attributes'] != null && 
                eventGroup['attributes']['name'] != null) {
              
              final eventName = eventGroup['attributes']['name'].toString();
              eventAidStations[eventName] = []; // Initialize with empty list by default
              
              // Check if we have events in relationships
              if (eventGroup['relationships'] != null && 
                  eventGroup['relationships']['events'] != null &&
                  eventGroup['relationships']['events']['data'] is List) {
                
                final events = eventGroup['relationships']['events']['data'];
                
                for (var event in events) {
                  try {
                    if (event['id'] != null) {
                      final eventId = event['id'].toString();
                      final eventResponse = await http.get(
                        Uri.parse('${_baseUrl}api/v1/events/$eventId'),
                        headers: {
                          'Authorization': token,
                          'Accept': 'application/json',
                        },
                      );
                      
                      if (eventResponse.statusCode == 200) {
                        final eventData = jsonDecode(eventResponse.body);
                        if (eventData['data']?['attributes']?['splitNames'] is List) {
                          eventAidStations[eventName] = 
                            List<String>.from(eventData['data']['attributes']['splitNames']);
                          break; // Use the first valid event's aid stations
                        }
                      }
                    }
                  } catch (e) {
                    print('Error processing event: $e');
                    continue;
                  }
                }
              }
            }
          }
        }
        return eventAidStations;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please try logging in again.');
      } else {
        throw Exception('Failed to load events (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Error in fetchEventDetails: $e');
    }
  }

  Future<Map<int, Map<String, String>>> fetchParticipantNames({
    required String eventName,
  }) async {
    final token = _prefs.token;
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

  Future<bool> syncEntries(String eventSlug, Map<String, dynamic> entriesPayload) async {
    final token = _prefs.token;
    if (token == null) {
      throw Exception('No authentication token found');
    }

    // TODO: Validate entriesPayload structure before proceeding
    print('Payload to sync:');
    print(jsonEncode(entriesPayload));

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/event_groups/$eventSlug/import?data_format=jsonapi_batch'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(entriesPayload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      developer.log(
        'Entries synced successfully.',
        name: 'NetworkManager.syncEntries',
      );
      return true;
    } else {
      throw Exception('Failed to sync entries (${response.statusCode}): ${response.body}');
    }
  }
}
