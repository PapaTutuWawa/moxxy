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
import 'package:moxxyv2/ui/pages/profile/conversationheader.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/ui/pages/profile/selfheader.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';

int affiliationToInt(Affiliation a) => switch (a) {
      Affiliation.owner => 4,
      Affiliation.admin => 3,
      Affiliation.member => 2,
      Affiliation.none => 1,
      Affiliation.outcast => 0,
    };

int affiliationSortingFunction(Affiliation a, Affiliation b) =>
    affiliationToInt(a).compareTo(affiliationToInt(b));

int groupchatMemberSortingFunction(GroupchatMember a, GroupchatMember b) {
  if (a.affiliation == b.affiliation) {
    return b.nick.compareTo(a.nick);
  }

  return affiliationSortingFunction(b.affiliation, a.affiliation);
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

    // TODO: Handle the display of our own data more gracefully. Maybe keep a special
    //       GroupchatMember that also stores our own affiliation and role so that we can
    //       cache it.
    // TODO: That also requires that we render that element separately so that we can just bypass
    //       the avatar data and just pull it from one of the BLoCs.
    final members = List.of(result.members)
      ..add(
        GroupchatMember(
          '',
          '',
          t.messages.you,
          Role.none,
          Affiliation.none,
          null,
          null,
          null,
        ),
      )
      ..sort(groupchatMemberSortingFunction);

    setState(() {
      _members = members;
    });
  }

  @override
  void initState() {
    super.initState();
    _initStateAsync();
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
        return ListTile(
          leading: CachingXMPPAvatar(
            jid: '${widget.arguments.jid}/${_members![index].nick}',
            radius: 20,
            hasContactId: false,
            isGroupchat: true,
            shouldRequest: false,
          ),
          title: Text(_members![index].nick),
          subtitle: switch (_members![index].affiliation) {
            // TODO: i18n
            Affiliation.owner => const Text(
                'Owner',
                style: TextStyle(color: Colors.red),
              ),
            Affiliation.admin => const Text(
                'Admin',
                style: TextStyle(color: Colors.green),
              ),
            Affiliation.member => null,
            Affiliation.none => null,
            Affiliation.outcast => null,
          },
        );
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
