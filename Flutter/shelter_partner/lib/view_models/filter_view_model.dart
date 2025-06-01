import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/app_user.dart';
import 'package:shelter_partner/repositories/filter_repository.dart';

class FilterViewModel extends StateNotifier<AsyncValue<AppUser?>> {
  final FilterRepository _repository;
  final Ref ref;

  FilterViewModel(this._repository, this.ref)
    : super(const AsyncValue.data(null));

  Future<void> saveFilterExpression(
    List<Map<String, dynamic>> serializedFilterElements,
    Map<String, String> serializedOperatorsBetween,
    String collection,
    String documentID,
    String filterFieldPath,
  ) async {
    await _repository.saveFilterExpression(collection, documentID, {
      'filterElements': serializedFilterElements,
      'operatorsBetween': serializedOperatorsBetween,
    }, filterFieldPath);
  }

  Future<Map<String, dynamic>?> loadFilterExpression(
    String title,
    String collection,
    String documentID,
    String filterFieldPath,
  ) async {
    final result = await _repository.loadFilterExpression(
      collection,
      documentID,
      filterFieldPath,
    );
    return result;
  }
}

final filterViewModelProvider =
    StateNotifierProvider<FilterViewModel, AsyncValue<AppUser?>>((ref) {
      final repository = ref.watch(
        filterRepositoryProvider,
      ); // Access the repository
      return FilterViewModel(repository, ref); // Pass the repository and ref
    });
