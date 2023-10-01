import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/groupchat_member.dart';
import 'package:moxxyv2/ui/bloc/server_info_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/profile/conversationheader.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/ui/pages/profile/selfheader.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';

extension AffiliationIntValue on Affiliation {
  int get number => switch (this) {
        Affiliation.owner => 4,
        Affiliation.admin => 3,
        Affiliation.member => 2,
        Affiliation.none => 1,
        Affiliation.outcast => 0,
      };
}

/// [Comparator] implementation to achieve grouping of affiliations and sorting
/// by nick name inside each group.
int _groupchatMemberComparator(GroupchatMember a, GroupchatMember b) {
  if (a.affiliation == b.affiliation) {
    return b.nick.compareTo(a.nick);
  }

  return b.affiliation.number.compareTo(a.affiliation.number);
}

class ProfileView extends StatefulWidget {
  const ProfileView(this.arguments, {super.key});

  final ProfileArguments arguments;

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  List<GroupchatMember>? _members;

  Future<void> _initStateAsync() async {
    if (widget.arguments.type != ConversationType.groupchat) {
      return;
    }

    final result = (await getForegroundService().send(
      GetMembersForGroupchatCommand(
        jid: widget.arguments.jid,
      ),
    ))! as GroupchatMembersResult;

    // TODO: Should be sort in the background?
    // TODO: That also requires that we render that element separately so that we can just bypass
    //       the avatar data and just pull it from one of the BLoCs.
    final members = List.of(result.members)..sort(_groupchatMemberComparator);

    setState(() {
      _members = members;
    });
  }

  @override
  void initState() {
    super.initState();
    _initStateAsync();
  }

  Widget _buildMemberTile(GroupchatMember member) {
    if (member.isSelf) {
      return ListTile(
        leading: CachingXMPPAvatar.self(radius: 20),
        title: Text(
          t.messages.you,
          style: const TextStyle(
            color: primaryColor,
          ),
        ),
        subtitle: Text(
          member.nick,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      return ListTile(
        leading: CachingXMPPAvatar(
          jid: '${widget.arguments.jid}/${member.nick}',
          radius: 20,
          hasContactId: false,
          isGroupchat: true,
          // TODO(Unknown): Request avatars at some point
          shouldRequest: false,
        ),
        title: Text(
          member.nick,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: switch (member.affiliation) {
          // TODO: i18n
          Affiliation.owner => const Text(
              'Owner',
              style: TextStyle(color: Colors.red),
              overflow: TextOverflow.ellipsis,
            ),
          Affiliation.admin => const Text(
              'Admin',
              style: TextStyle(color: Colors.green),
              overflow: TextOverflow.ellipsis,
            ),
          Affiliation.member => null,
          Affiliation.none => null,
          Affiliation.outcast => null,
        },
      );
    }
  }

  Widget _buildMemberList() {
    if (_members == null) {
      return const SliverToBoxAdapter(
        child: CircularProgressIndicator(),
      );
    }

    return SliverList.builder(
      itemCount: _members!.length,
      itemBuilder: (context, index) {
        final member = _members![index];
        return _buildMemberTile(member);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: widget.arguments.isSelfProfile
                      ? SelfProfileHeader(widget.arguments)
                      : const ConversationProfileHeader(),
                ),
              ),
              if (widget.arguments.type == ConversationType.groupchat)
                _buildMemberList(),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Visibility(
              visible: widget.arguments.isSelfProfile,
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  context.read<ServerInfoBloc>().add(ServerInfoPageRequested());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
