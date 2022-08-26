part of 'share_selection_bloc.dart';

@freezed
class ShareSelectionState with _$ShareSelectionState {
  factory ShareSelectionState({
    // A deduplicated combination of the conversation and roster list
    @Default(<ShareListItem>[]) List<ShareListItem> items,
    // List of paths that we want to share
    @Default(<String>[]) List<String> paths,
    // List of selected items in items
    @Default(<int>[]) List<int> selection,
  }) = _ShareSelectionState;
}
