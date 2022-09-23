// TODO(PapaTutuWawa): Move into its own file under xeps/xep_0060/
abstract class PubSubError {}

class UnknownPubSubError extends PubSubError {}

class PreconditionsNotMetError extends PubSubError {}

class MalformedResponseError extends PubSubError {}

class NoItemReturnedError extends PubSubError {}
