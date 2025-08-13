enum MealChoice { veg, nonVeg }

class SelectionPayload {
  final String choice; // 'veg' or 'non-veg'
  final DateTime date; // selected day
  SelectionPayload({required this.choice, required this.date});

  Map<String, dynamic> toJson() => {
    'choice': choice,
    'timestamp': DateTime.now().toIso8601String(),
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
  };
}

class WeeklySelectionPayload {
  final Map<DateTime, MealChoice> weeklyChoices; // Map of date to meal choice
  WeeklySelectionPayload({required this.weeklyChoices});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {};
    weeklyChoices.forEach((date, choice) {
      jsonMap[DateTime(date.year, date.month, date.day).toIso8601String()] = choice.name;
    });
    return jsonMap;
  }
}

class AdminScanResult {
  final bool success;
  final String message;
  AdminScanResult({required this.success, required this.message});
}

class Submission {
  final String choice;
  final String timestamp;
  final String userId;
  final DateTime date;

  Submission({
    required this.choice,
    required this.timestamp,
    required this.userId,
    required this.date,
  });
}
