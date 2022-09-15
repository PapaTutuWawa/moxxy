abstract class PubSubError {}

class UnknownPubSubError extends PubSubError {}

class PreconditionsNotMetError extends PubSubError {}

class MalformedResponseError extends PubSubError {}

class NoItemReturnedError extends PubSubError {}


abstract class OmemoError {}

class OmemoUnknownError extends OmemoError {}
