import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:open_split_time_v2/services/preferences_service.dart';

class NetworkManager {
  static const _baseUrl = 'https://ost-stage.herokuapp.com/';
  final PreferencesService _prefs = PreferencesService();

  Future<int> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}'),
      );
      if(response.statusCode != 200) {
        print("HERE!");
        return 0;
      } else {
        _prefs.token = null;
        _prefs.tokenExpiration = null;
        _prefs.email = null;
        print("here!");
        return 1;
      }
    } catch (e) {
      print('Connectivity check failed: $e');
      return 0;
    }
  }

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

  Future<Map<String, List<String>>> fetchEventDetails({String? eventName}) async {
    final token = _prefs.token;
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    try {
      String url = '${_baseUrl}api/v1/event_groups?filter[editable]=true&filter[availableLive]=true';
      if (eventName != null) {
        url += '&filter[name]=$eventName';
      }
      
      final response = await http.get(
        Uri.parse(url),
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

  Future<List<String>> fetchParticipantDetailsForGivenEvent({ required String eventSlug }) async {
    final token = _prefs.token;
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}api/v1/events/$eventSlug?include=efforts&fields[efforts]=fullName,bibNumber,age,gender,city,stateCode'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<String> participantInfo = [];


        if (data['included'] != null && data['included'] is List) {
          for (var effort in data['included']) {
            if (effort['attributes'] != null) {
              final String attributes = jsonEncode(effort['attributes']);
              participantInfo.add(attributes);
            }
          }
        }
        return participantInfo;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please try logging in again.');
      } else {
        throw Exception('Failed to load participant details (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching participant details: $e');
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
                  'fullName': effort['attributes']['fullName']?.toString() ?? '',
                  'age': effort['attributes']['age']?.toString() ?? '',
                  'gender': effort['attributes']['gender']?.toString() ?? '',
                  'city': effort['attributes']['city']?.toString() ?? '',
                  'stateCode': effort['attributes']['stateCode']?.toString() ?? '',
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

  /// Fetch full event details (efforts + events) for refresh data.
  /// Falls back to efforts-only if the server rejects the rich query.
  Future<Map<String, dynamic>> getEventDetailsRaw({
    required String eventSlug,
  }) async {
    final token = _prefs.token;
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

      /// Best-effort. If the endpoint is wrong/not supported, return null. Once you confirm the actual API route, adjust here.
  Future<Map<int, bool>?> fetchCrossCheckFlags({
    required String eventSlug,
    required String splitName,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      // GUESS: you may need to change this endpoint once confirmed.
      final uri = Uri.parse(
        '${_baseUrl}api/v1/events/$eventSlug/cross_check?split_name=$splitName',
      );

      final response = await http.get(uri, headers: {
        'Authorization': token,
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      // EXPECTED FORMAT (example):
      // { "not_expected_bibs": [1,2,3] }
      if (data is Map && data['not_expected_bibs'] is List) {
        final out = <int, bool>{};
        for (final v in (data['not_expected_bibs'] as List)) {
          final bib = v is int ? v : int.tryParse(v.toString());
          if (bib != null) out[bib] = true;
        }
        return out;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> syncEntries(String eventSlug, Map<String, dynamic> entriesPayload) async {
    final token = _prefs.token;
    if (token == null) {
      throw Exception('No authentication token found');
    }

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
