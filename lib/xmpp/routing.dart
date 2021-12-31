enum RoutingState {
  AUTHENTICATOR, // Route nonzas into the current authenticator
  ERROR, // Don't route anything; Stream error
  NEGOTIATOR, // Route nonzas into the negotiator
  STREAM_MANAGEMENT, // Route nonzas into the stream management handler
  RESOURCE_BIND, // Route stanzas into the resource binding handler
  NORMAL // Route stanzas into the regular event handler
}
