enum RoutingState {
  error,
  unauthenticated,
  performStartTLS,
  performSaslAuth,
  checkStreamManagement,
  performStreamResumption,
  bindResourcePreSM,
  enableSM,
  bindResource,
  handleStanzas
}
