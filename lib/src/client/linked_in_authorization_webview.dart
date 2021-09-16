import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart';
import 'package:linkedin_login/src/utils/global_variables.dart';
import 'package:linkedin_login/src/utils/helper.dart';
import 'package:linkedin_login/src/wrappers/authorization_code_response.dart';
import 'package:linkedin_login/src/wrappers/linked_in_error_object.dart';
import 'package:linkedin_login/src/wrappers/linked_in_token_object.dart';
import 'package:uuid/uuid.dart';

import '../../linkedin_login.dart';

/// Class will fetch code and access token from the user
/// It will show web view so that we can access to linked in auth page
class LinkedInAuthorization extends StatefulWidget {
  final Function onCallBack;
  final String redirectUrl;
  final String clientId, clientSecret;
  final PreferredSizeWidget appBar;
  final bool destroySession;
  final List<String> additionsScopes;

  // just in case that frontend in your team has changed redirect url
  final String frontendRedirectUrl;

  LinkedInAuthorization({
    @required this.onCallBack,
    @required this.redirectUrl,
    @required this.clientId,
    @required this.clientSecret,
    this.additionsScopes,
    this.appBar,
    this.destroySession,
    this.frontendRedirectUrl,
  });

  @override
  State createState() => _LinkedInAuthorizationState();
}

class _LinkedInAuthorizationState extends State<LinkedInAuthorization> {
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  StreamSubscription<String> _onUrlChanged;
  AuthorizationCodeResponse authorizationCodeResponse;

  List<String> fixesScopes = [
    ScopeParameters.rLiteProfile,
    ScopeParameters.rEmailAddress
  ];
  String clientState, loginUrl;

  List<String> scopes;
  @override
  void dispose() {
    _onUrlChanged.cancel();
    flutterWebViewPlugin.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    scopes = [
      ...fixesScopes,
      ...widget.additionsScopes?.where((e) => !(fixesScopes.contains(e))) ?? []
    ];
    clientState = Uuid().v4();

    flutterWebViewPlugin.close();

    loginUrl = '${GlobalVariables.URL_LINKED_IN_GET_AUTH_TOKEN}?'
        'response_type=code'
        '&client_id=${widget.clientId}'
        '&state=$clientState'
        '&redirect_uri=${widget.redirectUrl}'
        '&scope=${scopes.join('%20')}';

    // Add a listener to on url changed
    _onUrlChanged = flutterWebViewPlugin.onUrlChanged.listen((String url) {
      if (mounted &&
          (url.startsWith(widget.redirectUrl) ||
              (widget.frontendRedirectUrl != null &&
                  url.startsWith(widget.frontendRedirectUrl)))) {
        flutterWebViewPlugin.stopLoading();

        AuthorizationCodeResponse authCode =
            getAuthorizationCode(redirectUrl: url, clientState: clientState);
        _getAccessToken(authorizationCode: authCode).then(widget.onCallBack);
      }
    });
  }

  /// Method that will retrieve authorization code
  /// After auth code is received you can call API service to get access token
  /// from linkedIn
  /// If error happens it will be saved into [error] property of result object
  Future<AuthorizationCodeResponse> _getAccessToken(
      {AuthorizationCodeResponse authorizationCode}) async {
    // get access token based on code
    if (authorizationCode.code != null && authorizationCode.code.isNotEmpty) {
      final LinkedInTokenObject tokenObject =
          await _getUserProfile(authorizationCode);

      if (tokenObject.isSuccess) {
        authorizationCode.accessToken = tokenObject;
      } else {
        authorizationCode.errorObject = tokenObject.error;
      }
    }

    flutterWebViewPlugin.close();

    return authorizationCode;
  }

  /// Method for getting token object for current user
  /// This method will return you token & expiration time for that token
  Future<LinkedInTokenObject> _getUserProfile(
      AuthorizationCodeResponse codeDetails) async {
    final Map<String, dynamic> body = {
      'grant_type': 'authorization_code',
      'code': codeDetails.code,
      'redirect_uri': widget.redirectUrl,
      'client_id': widget.clientId,
      'client_secret': widget.clientSecret,
    };

    final response = await post(GlobalVariables.URL_LINKED_IN_GET_ACCESS_TOKEN,
        body: body,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded'
        },
        encoding: Encoding.getByName('utf-8'));

    if (response.statusCode == HttpStatus.ok) {
      return LinkedInTokenObject(
        accessToken: json.decode(response.body)['access_token'].toString(),
        expiresIn: json.decode(response.body)['expires_in'],
      );
    } else {
      return LinkedInTokenObject(
          error: LinkedInErrorObject(
        description: 'Failed to get token',
        statusCode: response.statusCode,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => WebviewScaffold(
        clearCookies: widget.destroySession,
        appBar: widget.appBar,
        url: loginUrl,
        hidden: true,
      );
}
