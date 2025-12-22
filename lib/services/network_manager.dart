import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class NetworkManager {
  static const _baseUrl = 'https://ost-stage.herokuapp.com/';

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
        Uri.parse('${_baseUrl}api/v1/event_groups?filter[name]=$name'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          print(data['data'][0]['attributes']['slug']);
          return data['data'][0]['attributes']['slug'];
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

  syncEntries(String eventSlug, Future<Map<String, dynamic>> entriesPayload) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final payload = await entriesPayload;

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/event_groups/$eventSlug/import'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      developer.log(
        'Entries synced successfully.',
        name: 'NetworkManager.syncEntries',
      );
    } else {
      throw Exception('Failed to sync entries (${response.statusCode}): ${response.body}');
    }
  }

  
}