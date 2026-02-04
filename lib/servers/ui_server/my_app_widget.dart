import 'package:flutter/material.dart';
import 'package:jerelo/jerelo.dart';
import 'package:jerelo_sample/app_domain/dto/sign_in_creds.dart';
import 'package:jerelo_sample/app_domain/dto/theme_config.dart';
import 'package:jerelo_sample/servers/ui_server/ui_input.dart';
import 'package:jerelo_sample/servers/ui_server/ui_output.dart';
import 'package:jerelo_sample/servers/ui_server/ui_server.dart';

final class MyAppWidget extends StatefulWidget {
  final Bridge<UiOutput, UiInput> bridge;

  const MyAppWidget(
    this.bridge, {
    super.key,
    //
  });

  @override
  State<MyAppWidget> createState() => _MyAppState();
}

final class _MyAppState extends State<MyAppWidget> {
  var _isDisposed = false;

  bool _isLightMode = true;
  bool? _isSignedIn;
  String _meals = "";
  bool _showRefreshButton = false;

  @override
  void initState() {
    super.initState();

    widget.bridge
        .dequeue()
        .thenDo((value) {
          if (_isDisposed) {
            return Cont.terminate<(), UiInput>();
          }
          return Cont.of(value);
        })
        .thenFork((event) {
          return Cont.fromRun<(), ()>((runtime, observer) {
            handleUiInput(event);
            observer.onValue(());
          });
        })
        .forever()
        .trap((), (errors) {
          print("MyAppWidget ui loop terminated, errors=$errors");
        });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void handleUiInput(UiInput event) {
    if (event is SetConfigUiInput) {
      switch (event.config) {
        case ThemeConfig.light:
          setState(() {
            _isLightMode = true;
          });
          break;
        case ThemeConfig.dark:
          setState(() {
            _isLightMode = false;
          });
          break;
      }
    }

    if (event is GetSignInCredsUiInput) {
      setState(() {
        _isSignedIn = false;
        _showRefreshButton = false;
      });
    }

    if (event is GetSignOutTriggerUiInput) {
      setState(() {
        _isSignedIn = true;
      });
    }

    if (event is GetMealsTriggerUiInput) {
      setState(() {
        _showRefreshButton = true;
      });
    }

    if (event is ShowMealsUiInput) {
      setState(() {
        _meals = event.meals.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = _isSignedIn;
    return MaterialApp(
      themeMode: _isLightMode ? ThemeMode.light : ThemeMode.dark,
      home: Scaffold(
        body: Column(
          children: [
            MaterialButton(
              onPressed: () {
                widget.bridge.enqueue(GetMealsTriggerUiOutput()).ff(());
              },
              child: Text(_showRefreshButton ? "Refresh" : ""),
            ),

            MaterialButton(
              onPressed: () {
                if (isSignedIn != null) {
                  if (isSignedIn) {
                    widget.bridge
                        .enqueue(
                          GetSignOutTriggerUiOutput(
                            //
                          ),
                          //
                        )
                        .ff(());
                  } else {
                    widget.bridge
                        .enqueue(
                          GetSignInCredsUiOutput(
                            SignInCreds("prokhor.andrew@gmail.com", "password"),
                            //
                          ),
                          //
                        )
                        .ff(());
                  }
                }
              },
              child: Text(
                isSignedIn == null
                    ? ""
                    : isSignedIn
                    ? "Sign Out"
                    : "Sign In",
              ),
              //
            ),

            // comment
            Text("MEALS:  $_meals"),
          ],
        ),
      ),
    );
  }
}
