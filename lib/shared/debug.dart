enum DebugCommand {
  /// Clear the stream resumption state so that the next connection is fresh.
  clearStreamResumption(0),
  requestRoster(1),
  logAvailableMediaFiles(2);

  const DebugCommand(this.id);

  /// The id of the command
  final int id;
}
