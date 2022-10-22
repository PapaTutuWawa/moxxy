abstract class OmemoError {}

class UnknownOmemoError extends OmemoError {}

class InvalidAffixElementsException with Exception {}

class OmemoNotSupportedForContactException extends OmemoError {}

class EncryptionFailedException with Exception {}
