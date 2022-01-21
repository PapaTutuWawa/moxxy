enum RoutingState {
  error,
  unauthenticated,
  performSaslAuth,
  checkStreamManagement,
  performStreamResumption,
  bindResourcePreSM,
  enableSM,
  bindResource,
  handleStanzas
}
