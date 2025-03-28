import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import 'package:flutter/services.dart';
import 'openid_io.dart' if (dart.library.js_interop) 'openid_browser.dart';

const keycloakUri = 'http://localhost:5003/';
const scopes = [
  'profile',
  'openid',
  'roles',
  'email',
  'vacancy',
  'offline_access',
];

Credential? credential;

late final Client client;

Future<Client> getClient() async {
  var uri = Uri.parse(keycloakUri);
  if (!kIsWeb && Platform.isAndroid) uri = uri.replace(host: '10.0.2.2');
  var clientId = 'test-client';

  // var clientSecret = 'test-client';
  var issuer = await Issuer.discover(uri);
  return Client(issuer, clientId);
}

Future<void> main() async {
  client = await getClient();
  credential = await getRedirectResult(client, scopes: scopes);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'openid_client demo',
      home: MyHomePage(title: 'openid_client Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  UserInfo? userInfo;
  String? access_token;
  Duration? expires_in;

  @override
  void initState() {
    if (credential != null) {
      credential!.getUserInfo().then((userInfo) {
        setState(() {
          this.userInfo = userInfo;
          this.access_token = access_token;
          this.expires_in = expires_in;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (userInfo != null) ...[
              Text('Hello ${userInfo!.name}'),
              Text(userInfo!.email ?? ''),
              Text('Expires in ${expires_in ?? ''}'),
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: SelectableText(access_token ?? '', maxLines: 3),
              ),
              ElevatedButton(
                child: Text("Copy Token"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: access_token ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Access Token Copied!")),
                  );
                },
              ),
              OutlinedButton(
                child: const Text('Logout'),
                onPressed: () async {
                  setState(() {
                    userInfo = null;
                    access_token = null;
                  });
                },
              ),

              // implement a copy button
            ],
            if (userInfo == null)
              OutlinedButton(
                child: const Text('Login'),
                onPressed: () async {
                  var credential = await authenticate(client, scopes: scopes);
                  var userInfo = await credential.getUserInfo();
                  var tokenResponse = await credential.getTokenResponse(true);
                  print(tokenResponse);
                  setState(() {
                    this.userInfo = userInfo;
                    this.access_token = tokenResponse.accessToken;
                    this.expires_in = tokenResponse.expiresIn;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
