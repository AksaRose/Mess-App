import 'models.dart';

abstract class Backend {
  Future<void> saveSelection(SelectionPayload payload);
  Future<String?> getChoiceForDate(DateTime date);
  Future<int> getChangeCountForDate(DateTime date);
}


