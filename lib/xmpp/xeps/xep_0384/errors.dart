abstract class OmemoError {}

class UnknownOmemoError extends OmemoError {}

class InvalidAffixElementsException with Exception {}

class OmemoNotSupportedForContactException with Exception {}

class EncryptionFailedException with Exception {}
