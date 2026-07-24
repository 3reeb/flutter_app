import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL CALENDAR MODELS
// ────────────────────────────────────────────────────────────────────────────

class CalendarEvent {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;

  const CalendarEvent({
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.location = '',
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int),
      location: map['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'location': location,
      };
}

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  Map<String, dynamic> toMap() => {
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _DateRangeEventListCodec extends QLChannelCodec<DateRange, List<CalendarEvent>> {
  const _DateRangeEventListCodec();
  @override dynamic encode(DateRange args) => args.toMap();
  @override List<CalendarEvent> decode(dynamic data) {
    if (data == null) return [];
    return (data as List).map((e) => CalendarEvent.fromMap(Map<String, dynamic>.from(e))).toList();
  }
}

class _GetEventsBridge extends QLMethodBridge<DateRange, List<CalendarEvent>> {
  @override String get channelName => 'quantum_calendar/get_events';
  @override QLChannelCodec<DateRange, List<CalendarEvent>> get codec => const _DateRangeEventListCodec();
}

class _AddEventCodec extends QLChannelCodec<CalendarEvent, bool> {
  const _AddEventCodec();
  @override dynamic encode(CalendarEvent args) => args.toMap();
  @override bool decode(dynamic data) => data == true;
}

class _AddEventBridge extends QLMethodBridge<CalendarEvent, bool> {
  @override String get channelName => 'quantum_calendar/add_event';
  @override QLChannelCodec<CalendarEvent, bool> get codec => const _AddEventCodec();
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumCalendar {
  static final QuantumCalendar instance = QuantumCalendar._();

  QuantumCalendar._() {
    QLNativeBridgeRegistry.instance.register('quantum_calendar/get_events', _getEvents);
    QLNativeBridgeRegistry.instance.register('quantum_calendar/add_event', _addEvent);
  }

  final _getEvents = _GetEventsBridge();
  final _addEvent = _AddEventBridge();

  /// Gets simple event info for a date range (useful for checking user availability in Booking apps).
  QLAsyncSignal<List<CalendarEvent>> getEvents(DateTime start, DateTime end) {
    return _getEvents(DateRange(start: start, end: end));
  }

  /// Adds a new event to the user's default calendar (useful for "Add to Calendar" buttons).
  QLAsyncSignal<bool> addEvent(CalendarEvent event) {
    return _addEvent(event);
  }
}
