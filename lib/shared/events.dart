import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/shared/models/reaction_group.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';

part 'events.moxxy.dart';

const preStartLoggedInState = 'logged_in';
const preStartNotLoggedInState = 'not_logged_in';
