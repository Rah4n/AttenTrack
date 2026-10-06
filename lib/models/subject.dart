class Subject {
  String name;
  int held;
  int attended;

  Subject({
    required this.name,
    this.held = 0,
    this.attended = 0,
  });

  double get percentage {
    if (held == 0) return 0;
    return (attended / held) * 100;
  }

  void markPresent() {
    held++;
    attended++;
  }

  void markAbsent() {
    held++;
  }
int classesCanMiss(double target) {
  if (held == 0) return 0;

  int miss = 0;

  while (attended / (held + miss) >= target) {
    miss++;
  }

  return miss - 1;
}

int classesNeeded(double target) {
  if (held == 0) return 0;

  int need = 0;

  while ((attended + need) / (held + need) < target) {
    need++;
  }

  return need;
}
}