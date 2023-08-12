part of 'request_bloc.dart';

abstract class RequestEvent {}

class RequestsSetEvent extends RequestEvent {
  RequestsSetEvent(this.requests);

  final List<Request> requests;
}

class NextRequestEvent extends RequestEvent {}

class ResetRequestEvent extends RequestEvent {}
