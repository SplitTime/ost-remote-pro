import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:open_split_time_v2/controllers/live_entry_controller.dart';
import 'package:open_split_time_v2/services/network_manager.dart';

// Create a mock class for NetworkManager
class MockNetworkManager extends Mock implements NetworkManager {}

void main() {
  group('LiveEntryController', () {
    late LiveEntryController controller;
    late MockNetworkManager mockNetworkManager;

    setUp(() {
      mockNetworkManager = MockNetworkManager();
      controller = LiveEntryController(networkManager: mockNetworkManager);
    });

    test('should initialize with default values', () {
      expect(controller.bibNumber, '');
      expect(controller.athleteName, '');
      expect(controller.isContinuing, true);
      expect(controller.hasPacer, false);
      expect(controller.aidStation, '');
      expect(controller.eventName, '');
      expect(controller.eventSlug, '');
      expect(controller.athleteOrigin, '');
      expect(controller.athleteGender, '');
      expect(controller.athleteAge, '');
      expect(controller.entryTime, isNull);
    });

    test('should update bib number when updateBibNumber is called', () {
      controller.updateBibNumber('123');
      expect(controller.bibNumber, '123');
    });

    test('should update athlete name when updateAthleteName is called', () {
      controller.updateAthleteName('John Doe');
      expect(controller.athleteName, 'John Doe');
    });

    test('should update athlete origin when updateAthleteOrigin is called', () {
      controller.updateAthleteOrigin('Denver, CO');
      expect(controller.athleteOrigin, 'Denver, CO');
    });

    test('should update athlete gender when updateAthleteGender is called', () {
      controller.updateAthleteGender('Female');
      expect(controller.athleteGender, 'Female');
    });

    test('should update athlete age when updateAthleteAge is called', () {
      controller.updateAthleteAge('25');
      expect(controller.athleteAge, '25');
    });

    test('should toggle isContinuing to false when toggleIsContinuing(false) is called', () {
      expect(controller.isContinuing, true);
      controller.toggleIsContinuing(false);
      expect(controller.isContinuing, false);
    });

    test('should toggle isContinuing to true when toggleIsContinuing(true) is called', () {
      controller.toggleIsContinuing(false);
      controller.toggleIsContinuing(true);
      expect(controller.isContinuing, true);
    });

    test('should toggle hasPacer to true when toggleHasPacer(true) is called', () {
      expect(controller.hasPacer, false);
      controller.toggleHasPacer(true);
      expect(controller.hasPacer, true);
    });

    test('should toggle hasPacer to false when toggleHasPacer(false) is called', () {
      controller.toggleHasPacer(true);
      controller.toggleHasPacer(false);
      expect(controller.hasPacer, false);
    });

    test('should update aid station when updateAidStation is called', () {
      controller.updateAidStation('Station 1');
      expect(controller.aidStation, 'Station 1');
    });

    test('should update event name when updateEventName is called', () {
      controller.updateEventName('Marathon 2024');
      expect(controller.eventName, 'Marathon 2024');
    });

    test('should update event slug when updateEventSlug is called', () {
      controller.updateEventSlug('marathon-2024');
      expect(controller.eventSlug, 'marathon-2024');
    });

    test('should notify listeners when updateBibNumber is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateBibNumber('456');
      expect(notified, true);
    });

    test('should notify listeners when updateAthleteName is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateAthleteName('Jane Smith');
      expect(notified, true);
    });

    test('should notify listeners when updateAthleteOrigin is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateAthleteOrigin('Boulder, CO');
      expect(notified, true);
    });

    test('should notify listeners when updateAthleteGender is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateAthleteGender('Male');
      expect(notified, true);
    });

    test('should notify listeners when updateAthleteAge is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateAthleteAge('30');
      expect(notified, true);
    });

    test('should notify listeners when toggleIsContinuing is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.toggleIsContinuing(false);
      expect(notified, true);
    });

    test('should notify listeners when toggleHasPacer is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.toggleHasPacer(true);
      expect(notified, true);
    });

    test('should notify listeners when updateAidStation is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateAidStation('Checkpoint');
      expect(notified, true);
    });

    test('should notify listeners when updateEventName is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateEventName('Race Event');
      expect(notified, true);
    });

    test('should notify listeners when updateEventSlug is called', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateEventSlug('race-event');
      expect(notified, true);
    });

    test('updateAthleteInfo should clear name when bib number is empty', () {
      controller.updateAthleteName('John');
      controller.updateBibNumber('');
      controller.updateAthleteInfo();
      expect(controller.athleteName, '');
    });

    test('updateAthleteInfo should set defaults when bib is not in map', () {
      controller.updateBibNumber('999');
      controller.updateAthleteInfo();
      expect(controller.athleteAge, '100');
      expect(controller.athleteGender, 'Male');
      expect(controller.athleteOrigin, 'Somewhere, ST');
    });

    test('updateAthleteInfo should clear name when bib is invalid (not a number)', () {
      controller.updateBibNumber('abc');
      controller.updateAthleteInfo();
      expect(controller.athleteName, '');
    });

    test('stationControl should set entryTime', () {
      controller.updateBibNumber('100');
      final timeBefore = DateTime.now();
      controller.stationControl('in', 'device-1');
      final timeAfter = DateTime.now();
      
      expect(controller.entryTime, isNotNull);
      expect(controller.entryTime!.isAfter(timeBefore.subtract(const Duration(seconds: 1))), true);
      expect(controller.entryTime!.isBefore(timeAfter.add(const Duration(seconds: 1))), true);
    });

    test('stationControl should accept "in" direction', () {
      controller.updateBibNumber('100');
      expect(() => controller.stationControl('in', 'device'), returnsNormally);
    });

    test('stationControl should accept "out" direction', () {
      controller.updateBibNumber('100');
      expect(() => controller.stationControl('out', 'device'), returnsNormally);
    });

    test('stationControl should throw assertion error for invalid direction', () {
      controller.updateBibNumber('100');
      expect(() => controller.stationControl('invalid', 'device'), throwsAssertionError);
    });

    test('stationControl should throw assertion error for empty source', () {
      controller.updateBibNumber('100');
      expect(() => controller.stationControl('in', ''), throwsAssertionError);
    });

    test('stationControl with direction "out"', () {
      controller.updateBibNumber('200');
      final timeBefore = DateTime.now();
      controller.stationControl('out', 'device-2');
      final timeAfter = DateTime.now();
      
      expect(controller.entryTime, isNotNull);
      expect(controller.entryTime!.isAfter(timeBefore.subtract(const Duration(seconds: 1))), true);
      expect(controller.entryTime!.isBefore(timeAfter.add(const Duration(seconds: 1))), true);
    });

    test('should handle multiple sequential updates', () {
      controller.updateBibNumber('123');
      controller.updateAthleteName('Alice');
      controller.updateAthleteOrigin('NYC');
      
      expect(controller.bibNumber, '123');
      expect(controller.athleteName, 'Alice');
      expect(controller.athleteOrigin, 'NYC');
    });

    test('should allow resetting values to empty strings', () {
      controller.updateBibNumber('123');
      controller.updateAthleteName('Bob');
      
      controller.updateBibNumber('');
      controller.updateAthleteName('');
      
      expect(controller.bibNumber, '');
      expect(controller.athleteName, '');
    });

    test('should handle rapid toggle calls for isContinuing', () {
      controller.toggleIsContinuing(false);
      controller.toggleIsContinuing(true);
      controller.toggleIsContinuing(false);
      
      expect(controller.isContinuing, false);
    });

    test('should handle rapid toggle calls for hasPacer', () {
      controller.toggleHasPacer(true);
      controller.toggleHasPacer(false);
      controller.toggleHasPacer(true);
      
      expect(controller.hasPacer, true);
    });

    test('should update all athlete info fields together', () {
      controller.updateBibNumber('100');
      controller.updateAthleteName('Charlie');
      controller.updateAthleteOrigin('LA');
      controller.updateAthleteGender('Other');
      controller.updateAthleteAge('35');
      
      expect(controller.bibNumber, '100');
      expect(controller.athleteName, 'Charlie');
      expect(controller.athleteOrigin, 'LA');
      expect(controller.athleteGender, 'Other');
      expect(controller.athleteAge, '35');
    });

    test('should update all event info fields together', () {
      controller.updateAidStation('Mile 5');
      controller.updateEventName('10K Race');
      controller.updateEventSlug('10k-race');
      
      expect(controller.aidStation, 'Mile 5');
      expect(controller.eventName, '10K Race');
      expect(controller.eventSlug, '10k-race');
    });

    test('should have correct initial value for isContinuing', () {
      expect(controller.isContinuing, true);
    });

    test('should have correct initial value for hasPacer', () {
      expect(controller.hasPacer, false);
    });

    test('updateAthleteInfo notifies listeners', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      
      controller.updateBibNumber('100');
      controller.updateAthleteInfo();
      
      expect(notified, true);
    });

    test('stationControl with bib not in map and valid direction', () {
      controller.updateBibNumber('999');
      final timeBefore = DateTime.now();
      
      controller.stationControl('in', 'source-1');
      
      // Should still set entryTime even if bib not found
      expect(controller.entryTime, isNotNull);
      expect(controller.entryTime!.isAfter(timeBefore.subtract(const Duration(seconds: 1))), true);
    });
  });
}