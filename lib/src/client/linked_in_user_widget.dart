import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:linkedin_login/src/utils/constants.dart';
import 'package:linkedin_login/src/model/linked_in_user_model.dart';
import 'package:linkedin_login/src/client/linked_in_authorization_webview.dart';
import 'package:http/http.dart';
import 'package:linkedin_login/src/wrappers/authorization_code_response.dart';

/// This class is responsible to fetch all information for user after we get
/// token and code from LinkedIn
class LinkedInUserWidget extends StatefulWidget {
  final Function(LinkedInUserModel, Response ) onGetUserProfile;
  final Function catchError;
  final String redirectUrl;
  final String clientId, clientSecret;
  final PreferredSizeWidget appBar;
  final bool destroySession;
  final List<String> projection;
  final List<String> additionsScopes;

  /// Client state parameter needs to be unique range of characters - random one
  LinkedInUserWidget({
    @required this.onGetUserProfile,
    @required this.redirectUrl,
    @required this.clientId,
    @required this.clientSecret,
    this.catchError,
    this.destroySession = false,
    this.appBar,
    this.projection = const [
      ProjectionParameters.id,
      ProjectionParameters.localizedFirstName,
      ProjectionParameters.localizedLastName,
      ProjectionParameters.firstName,
      ProjectionParameters.lastName,
    ],
    this.additionsScopes,
  })  : assert(onGetUserProfile != null),
        assert(redirectUrl != null),
        assert(clientId != null),
        assert(clientSecret != null),
        assert(destroySession != null),
        assert(projection != null);

  @override
  State createState() => _LinkedInUserWidgetState();
}

/// Class [_LinkedInUserWidgetState] is handling changes after user is singed in
/// which will have as result user profile on the end
class _LinkedInUserWidgetState extends State<LinkedInUserWidget> {
  String urlLinkedInUserProfile = 'https://api.linkedin.com/v2/me';
  final urlLinkedInEmailAddress =
      'https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))';

  @override
  void initState() {
    super.initState();

    String projection = 'projection=(${widget.projection.join(",")})';
    urlLinkedInUserProfile = '$urlLinkedInUserProfile?$projection';
  }

  @override
  Widget build(BuildContext context) => LinkedInAuthorization(
        destroySession: widget.destroySession,
        redirectUrl: widget.redirectUrl,
        clientSecret: widget.clientSecret,
        clientId: widget.clientId,
        additionsScopes: widget.additionsScopes,
        appBar: widget.appBar,
        onCallBack: (AuthorizationCodeResponse result) {
          if (result != null && result.accessToken != null) {
            get(
              urlLinkedInUserProfile,
              headers: {
                HttpHeaders.acceptHeader: 'application/json',
                HttpHeaders.authorizationHeader:
                    'Bearer ${result.accessToken.accessToken}'
              },
            ).then((basicProfile) {
              get(
                urlLinkedInEmailAddress,
                headers: {
                  HttpHeaders.acceptHeader: 'application/json',
                  HttpHeaders.authorizationHeader:
                      'Bearer ${result.accessToken.accessToken}'
                },
              ).then((emailProfile) {
                // Get basic user profile
                final LinkedInUserModel linkedInUser =
                    LinkedInUserModel.fromJson(json.decode(basicProfile.body));
                // Get email for current user profile
                linkedInUser.email = LinkedInProfileEmail.fromJson(
                  json.decode(emailProfile.body),
                );
                linkedInUser.token = result.accessToken;

                // Notify parent class / widget that we have user
                widget.onGetUserProfile(linkedInUser, basicProfile);
              });
            });
          } else {
            // If inner class catch the error, then forward it to parent class
            if (result.error != null && result.error.description.isNotEmpty) {
              widget.catchError(result.error);
            }
          }
        },
      );
}
