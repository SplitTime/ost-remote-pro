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
      expect(controller.athleteAge, '');
      expect(controller.athleteGender, '');
      expect(controller.athleteOrigin, '');
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

    test('should have correct initial value for isContinuing', () {
      expect(controller.isContinuing, true);
    });

    test('should have correct initial value for hasPacer', () {
      expect(controller.hasPacer, false);
    });

  });
}