part of 'share_selection_bloc.dart';

@freezed
class ShareSelectionState with _$ShareSelectionState {
  factory ShareSelectionState({
    // A deduplicated combination of the conversation and roster list
    @Default(<ShareListItem>[]) List<ShareListItem> items,
    // List of paths that we want to share
    @Default(<String>[]) List<String> paths,
    // The text we want to share
    @Default(null) String? text,
    // List of selected items in items
    @Default(<int>[]) List<int> selection,
    // The type of data we try to share
    @Default(ShareSelectionType.media) ShareSelectionType type,
  }) = _ShareSelectionState;
}
