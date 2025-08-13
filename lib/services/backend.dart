import 'models.dart';

abstract class Backend {
  Future<void> saveSelection(SelectionPayload payload);
  Future<String?> getChoiceForDate(DateTime date);
  Future<int> getChangeCountForDate(DateTime date);
  Future<void> submitWeeklyChoice(WeeklySelectionPayload payload);
  Future<Map<DateTime, String>> getWeeklySubmissions(String userId);
  Future<Submission?> getSubmissionForDate(String userId, DateTime date);
  Future<void> submitSingleWeeklyChoice(WeeklySelectionPayload payload);
}


