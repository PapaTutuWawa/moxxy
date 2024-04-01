import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/state/preferences.dart';

/// Taken from https://github.com/SimonBrazell/privacy-redirect/blob/master/src/assets/javascripts/helpers/youtube.js
const _youtubeHosts = [
  'm.youtube.com',
  'youtube.com',
  'img.youtube.com',
  'www.youtube.com',
  'youtube-nocookie.com',
  'www.youtube-nocookie.com',
  'youtu.be',
  's.ytimg.com',
  'music.youtube.com',
];

/// Taken from https://github.com/SimonBrazell/privacy-redirect/blob/master/src/assets/javascripts/helpers/twitter.js
const _twitterHosts = [
  'twitter.com',
  'www.twitter.com',
  'mobile.twitter.com',
  'pbs.twimg.com',
  'video.twimg.com',
];

/// Check if [uri] is a link to a website we have a redirect configured for. If yes, replace
/// the host in [uri] with the redirect and return the redirected Uri. If not, or if the
/// redirect is disabled, just return [uri].
Uri redirectUrl(Uri uri) {
  // Check for Youtube links
  final bloc = GetIt.I.get<PreferencesCubit>();
  if (bloc.state.enableYoutubeRedirect) {
    if (_youtubeHosts.contains(uri.host)) {
      return uri.replace(host: bloc.state.youtubeRedirect);
    }
  }

  // Check for Twitter links
  if (bloc.state.enableTwitterRedirect) {
    if (_twitterHosts.contains(uri.host)) {
      return uri.replace(host: bloc.state.twitterRedirect);
    }
  }

  return uri;
}
