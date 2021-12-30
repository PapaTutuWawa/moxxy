enum RoutingState {
  AUTHENTICATOR, // Route nonzas into the current authenticator
  ERROR, // Don't route anything; Stream error
  NEGOTIATOR, // Route nonzas into the negotiator
  RESOURCE_BIND, // Route stanzas into the resource binding handler
  NORMAL // Route stanzas into the regular event handler
}
