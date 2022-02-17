import "package:moxxyv2/ui/widgets/sharedimage.dart";
import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";
import "package:logging/logging.dart";

class SendFilesPage extends StatelessWidget {
  final Logger _log;

  SendFilesPage({ Key? key }) : _log = Logger("SendFilesPage"), super(key: key);

  void _sendFiles(BuildContext context) {
    _log.info("Stub: Sending files");

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    // TODO: Fix the typography
    return SafeArea(
      child: Scaffold(
        // appBar: BorderlessTopbar.justBackButton(),
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              child: BackButton()
            ),
            Positioned(
              top: 0,
              left: 0,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fexternal-preview.redd.it%2FOXnUhRPxLd1a9yV5XSBSfUL93R18yHlq6NvjDf40s5E.jpg%3Fauto%3Dwebp%26s%3D6c5eb604e79dce3a513cc80c10313b33067a7991&f=1&nofb=1")
                  ]
                )
              )
            ),
            // TODO: Add a TextField for entering a message
            Positioned(
              bottom: 2 * paddingVeryLarge,
              left: 0,
              child: SizedBox(
                width: size.width,
                height: 100,
                // TODO: Replace with a ListView
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: SharedMediaContainer(
                          onTap: () {},
                          showBorder: true,
                          drawShadow: true,
                          image: const NetworkImage("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fexternal-preview.redd.it%2FOXnUhRPxLd1a9yV5XSBSfUL93R18yHlq6NvjDf40s5E.jpg%3Fauto%3Dwebp%26s%3D6c5eb604e79dce3a513cc80c10313b33067a7991&f=1&nofb=1")
                        )
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: SharedMediaContainer(
                          onTap: () {},
                          showBorder: false,
                          drawShadow: true,
                          image: const NetworkImage("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fwallpapercave.com%2Fwp%2Fwp8027834.jpg&f=1&nofb=1")
                        )
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: SharedMediaContainer(
                          onTap: () => _log.info("Stub: Adding file"),
                          drawShadow: true,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey.withOpacity(0.6)
                            ),
                            child: const Center(
                              child: Icon(Icons.add),
                            )
                          )
                        )
                      )
                    ]
                  )
                )
              )
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: SizedBox(
                  height: 45.0,
                  width: 45.0,
                  // TODO
                  child: FloatingActionButton(
                    child: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendFiles(context)
                  )
                )
              )
            )
          ]
        )
      )
    );
  }
}
