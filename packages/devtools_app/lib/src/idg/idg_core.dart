class Recipe {}

abstract class Sensor {
  Sensor(this.presentationName, this.sensorName);

  String presentationName;
  String sensorName;

  void trigger();
}

class PresenceSensor extends Sensor {
  PresenceSensor(String presentationName, String sensorName)
      : super(presentationName, sensorName);

  bool triggered;

  @override
  void trigger() {
    triggered = true;
  }
}

class CountingSensor extends Sensor {
  CountingSensor(String presentationName, String sensorName, {this.counter = 0})
      : super(presentationName, sensorName);

  int counter;
  @override
  void trigger() {
    counter++;
  }
}
