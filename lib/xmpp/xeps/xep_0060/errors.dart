abstract class PubSubError {}

class UnknownPubSubError extends PubSubError {}

class PreconditionsNotMetError extends PubSubError {}

class MalformedResponseError extends PubSubError {}

class NoItemReturnedError extends PubSubError {}

/// Returned if we can guess that the server, by which I mean ejabberd, rejected
/// the publish due to not liking that we set "max_items" to "max".
/// NOTE: This workaround is required due to https://github.com/processone/ejabberd/issues/3044
// TODO(Unknown): Remove once ejabberd fixes it
class EjabberdMaxItemsError extends PubSubError {}
