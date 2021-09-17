// ignore_for_file: avoid_classes_with_only_static_members
/// Currently supported projection options
class ProjectionParameters {
  static const String id = 'id';
  static const String localizedLastName = 'localizedLastName';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String localizedFirstName = 'localizedFirstName';
  static const String profilePicture =
      'profilePicture(displayImage~:playableStreams)';
  static const String vanityName = 'vanityName';
  static const String localizedHeadline = 'localizedHeadline';
  static const String headline = 'headline';

  static const List<String> projectionWithoutPicture = const [
    id,
    localizedFirstName,
    localizedLastName,
    firstName,
    lastName,
  ];

  static const List<String> fullProjection = const [
    id,
    localizedFirstName,
    localizedLastName,
    firstName,
    lastName,
    profilePicture,
  ];

  static const List<String> basicProfileProjection = [
    id,
    firstName,
    lastName,
    vanityName,
    headline,
    profilePicture,
    localizedFirstName,
    localizedLastName,
    localizedHeadline,
  ];
}

class ScopeParameters {
  static const String wMemberSocial = 'w_member_social';
  static const String rBasicProfile = 'r_basicprofile';
  static const String rLiteProfile = 'r_liteprofile';
  static const String rEmailAddress = 'r_emailaddress';

  static const List<String> deafultProfile = [
    rLiteProfile,
    rEmailAddress,
  ];

   static const List<String> basicProfile = [
    rLiteProfile,
    rEmailAddress,
    rBasicProfile,
  ];
    static const List<String> basicProfileWithMemberSocial = [
    rLiteProfile,
    rEmailAddress,
    rBasicProfile,
    wMemberSocial,
  ];
}
