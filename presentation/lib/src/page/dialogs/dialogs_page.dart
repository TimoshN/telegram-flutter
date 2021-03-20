import 'package:flutter/material.dart';
import 'package:presentation/presentation.dart';
import 'package:presentation/src/tile/tile.dart';
import 'package:tdlib/td_api.dart' as td;
import 'package:jugger/jugger.dart' as j;

class DialogsPage extends StatefulWidget {
  const DialogsPage({Key? key}) : super(key: key);

  @override
  DialogsPageState createState() => DialogsPageState();
}

class DialogsPageState extends State<DialogsPage> {
  @j.inject
  late ChatTileFactory chatTileFactory;

  @override
  void initState() {
    appComponent.injectDialogsState(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialogs'),
      ),
      body: StreamBuilder<List<td.Chat>>(
        stream: appComponent.getChatRepository().chats,
        initialData: const <td.Chat>[],
        builder:
            (BuildContext context, AsyncSnapshot<List<td.Chat>?> snapshot) {
          final List<td.Chat> chats = snapshot.data ?? const <td.Chat>[];

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int index) {
              return chatTileFactory.create(chats[index]);
            },
          );
        },
      ),
    );
  }
}