class BlockJidUIAction {
  final String jid;

  const BlockJidUIAction({ required this.jid });
}

class UnblockJidUIAction {
  final String jid;

  const UnblockJidUIAction({ required this.jid });
}

class UnblockAllUIAction {
  const UnblockAllUIAction();
}

class BlocklistDiffAction {
  final List<String> newItems;
  final List<String> removedItems;

  const BlocklistDiffAction({
      required this.newItems,
      required this.removedItems
  });
}
