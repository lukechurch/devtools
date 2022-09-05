import 'dart:developer' as dev;

class IDGEvent {
  String eventKind;
  Map<String, Object> eventData;

  IDGEvent(this.eventKind, this.eventData);
}

void reportAppStart() => reportEvent(IDGEvent("APP_START", {}));

void reportEvent(IDGEvent event) {
  print("idg: reportEvent ${event.eventKind}");
  // Add a comment here
  dev.postEvent(event.eventKind, event.eventData);
}
