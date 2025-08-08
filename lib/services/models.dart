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

class AdminScanResult {
  final bool success;
  final String message;
  AdminScanResult({required this.success, required this.message});
}
