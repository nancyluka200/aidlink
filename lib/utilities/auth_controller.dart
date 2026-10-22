import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_url.dart';
import 'package:flutter/foundation.dart';

class AuthController extends GetxController {
  final createAccountUrl   = Uri.parse('$baseUrl/api/users/create-account');
  final signInUrl          = Uri.parse('$baseUrl/api/users/sign-in');
  final completeProfileUrl = Uri.parse('$baseUrl/api/users/complete-profile');
  final getProfileUrl      = Uri.parse('$baseUrl/api/users/profile');

  // ── Auth State ────────────────────────────────────────────────────────────
  RxBool   isSignedIn  = false.obs;
  RxString token       = ''.obs;
  RxString signedEmail = ''.obs;
  RxBool   isAdmin     = false.obs;

  // ── Email Verification ────────────────────────────────────────────────────
  RxBool emailVerified = false.obs;

  // ── Basic Info ────────────────────────────────────────────────────────────
  RxString firstName         = ''.obs;
  RxString lastName          = ''.obs;
  RxInt    age               = 0.obs;
  RxString citizenshipStatus = ''.obs;

  // ── Location & Household ──────────────────────────────────────────────────
  RxString location      = ''.obs;
  RxInt    householdSize = 0.obs;

  // ── Financial & Employment ────────────────────────────────────────────────
  RxInt    income           = 0.obs;
  RxString employmentStatus = ''.obs;
  RxBool   isStudent        = false.obs;
  RxString educationLevel   = ''.obs;

  // ── Disability Info ───────────────────────────────────────────────────────
  RxString       disabilityType   = ''.obs;
  RxBool         disabilityStatus = false.obs;
  RxList<String> disabilities     = <String>[].obs;

  // ── PWD Card ──────────────────────────────────────────────────────────────
  RxBool   pwdCardStatus   = false.obs;
  RxString pwdCardNumber   = ''.obs;
  RxString pwdCardImageUrl = ''.obs;

  // ── PWD Card Verification (from admin review) ─────────────────────────────
  RxString pwdCardVerificationStatus = 'unverified'.obs;
  RxString pwdCardRejectionReason    = ''.obs;

  // ── Applicant Type ────────────────────────────────────────────────────────
  RxString applicantType         = ''.obs;
  RxString caretakerName         = ''.obs;
  RxString caretakerRelationship = ''.obs;
  RxString caretakerPhone        = ''.obs;
  RxString caretakerNationalId   = ''.obs;

  // ── Profile State ─────────────────────────────────────────────────────────
  RxBool profileCompleted = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token') ?? '';
    if (savedToken.isNotEmpty) {
      token.value = savedToken;
      isSignedIn.value = true;
      await checkProfileStatus();
    }
  }

  // ── CRITICAL: save token AND wait for it before returning ─────────────────
  Future<void> _saveToken(String t) async {
    token.value = t; // set in memory immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', t); // then persist
  }

  Future<void> _clearToken() async {
    token.value = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  String get fullName => '${firstName.value} ${lastName.value}'.trim();
  bool get isCaretakerApplication => applicantType.value == 'Caretaker';

  bool get isPwdCardVerified => pwdCardVerificationStatus.value == 'verified';
  bool get isPwdCardRejected => pwdCardVerificationStatus.value == 'rejected';
  bool get isPwdCardPending  => pwdCardVerificationStatus.value == 'pending';

  static String? validateKenyanNationalId(String? value) {
    if (value == null || value.isEmpty) return 'National ID is required';
    final cleaned = value.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(cleaned)) return 'ID must be exactly 8 digits';
    if (cleaned.startsWith('0')) return 'Enter a valid Kenyan National ID';
    final firstDigit = int.parse(cleaned[0]);
    if (firstDigit < 1 || firstDigit > 3) return 'Enter a valid Kenyan National ID';
    return null;
  }

  // ── Create Account ────────────────────────────────────────────────────────
  Future<String> createAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        createAccountUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName':  lastName,
          'email':     email,
          'password':  password,
        }),
      );
      if (response.statusCode == 200) {
        final responseToken = response.headers['x-auth-token'];
        if (responseToken != null && responseToken.isNotEmpty) {
          await _saveToken(responseToken); // await ensures token is set before navigation
          isSignedIn.value     = true;
          signedEmail.value    = email;
          this.firstName.value = firstName;
          this.lastName.value  = lastName;
          emailVerified.value  = false;
          isAdmin.value        = false;
        }
        return 'success';
      } else {
        return response.body.toString();
      }
    } catch (error) {
      return 'Network error: $error';
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────
  Future<String> signIn(String email, String password) async {
    try {
      final response = await http.post(
        signInUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseToken = response.headers['x-auth-token'];
        if (responseToken == null || responseToken.isEmpty) {
          return 'No token received from server';
        }

        // ── Save token FIRST and await it — this ensures auth.token.value
        //    is set before any admin page tries to use it ──────────────────
        await _saveToken(responseToken);
        isSignedIn.value  = true;
        signedEmail.value = email;

        // ── Parse response body ───────────────────────────────────────────
        try {
          final body = jsonDecode(response.body);
          emailVerified.value = body['emailVerified'] ?? false;
          isAdmin.value       = body['isAdmin']       ?? false;
          pwdCardVerificationStatus.value =
              body['pwdCardVerificationStatus'] ?? 'unverified';
          pwdCardRejectionReason.value =
              body['pwdCardRejectionReason'] ?? '';
        } catch (_) {}

        // ── Load full profile ─────────────────────────────────────────────
        await checkProfileStatus();

        return 'success';
      } else {
        return response.body.toString();
      }
    } catch (error) {
      return 'Network error: $error';
    }
  }

  // ── Complete Profile ──────────────────────────────────────────────────────
  Future<String> completeProfile({
    required int age,
    required String location,
    required int income,
    required int householdSize,
    required String employmentStatus,
    required String educationLevel,
    required String citizenshipStatus,
    required String disabilityType,
    required bool disabilityStatus,
    required bool pwdCardStatus,
    String? pwdCardNumber,
    String? pwdCardImageUrl,
    List<String> disabilities = const [],
    bool isStudent = false,
    required String applicantType,
    String? caretakerName,
    String? caretakerRelationship,
    String? caretakerPhone,
    String? caretakerNationalId,
  }) async {
    try {
      final response = await http.put(
        completeProfileUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token.value,
        },
        body: jsonEncode({
          'age':               age,
          'location':          location,
          'income':            income,
          'householdSize':     householdSize,
          'employmentStatus':  employmentStatus,
          'educationLevel':    educationLevel,
          'citizenshipStatus': citizenshipStatus,
          'disabilityType':    disabilityType,
          'disabilityStatus':  disabilityStatus,
          'pwdCardStatus':     pwdCardStatus,
          'pwdCardNumber':     pwdCardNumber    ?? '',
          'pwdCardImageUrl':   pwdCardImageUrl  ?? '',
          'disabilities':      disabilities,
          'isStudent':         isStudent,
          'applicantType':     applicantType,
          'caretakerName':         caretakerName         ?? '',
          'caretakerRelationship': caretakerRelationship ?? '',
          'caretakerPhone':        caretakerPhone        ?? '',
          'caretakerNationalId':   caretakerNationalId   ?? '',
        }),
      );
      if (response.statusCode == 200) {
        this.age.value              = age;
        this.location.value         = location;
        this.income.value           = income;
        this.householdSize.value    = householdSize;
        this.employmentStatus.value = employmentStatus;
        this.educationLevel.value   = educationLevel;
        this.citizenshipStatus.value = citizenshipStatus;
        this.disabilityType.value   = disabilityType;
        this.disabilityStatus.value = disabilityStatus;
        this.pwdCardStatus.value    = pwdCardStatus;
        this.pwdCardNumber.value    = pwdCardNumber    ?? '';
        this.pwdCardImageUrl.value  = pwdCardImageUrl  ?? '';
        this.disabilities.value     = disabilities;
        this.isStudent.value        = isStudent;
        this.applicantType.value    = applicantType;
        this.caretakerName.value         = caretakerName         ?? '';
        this.caretakerRelationship.value = caretakerRelationship ?? '';
        this.caretakerPhone.value        = caretakerPhone        ?? '';
        this.caretakerNationalId.value   = caretakerNationalId   ?? '';
        profileCompleted.value = true;

        if (pwdCardStatus) {
          pwdCardVerificationStatus.value = 'pending';
          pwdCardRejectionReason.value    = '';
        }
        return 'success';
      } else {
        return response.body.toString();
      }
    } catch (error) {
      return 'Network error: $error';
    }
  }

  // ── Check / Load Profile from Backend ────────────────────────────────────
  Future<void> checkProfileStatus() async {
    if (token.value.isEmpty) return; // don't attempt if no token
    try {
      final response = await http.get(
        getProfileUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token.value,
        },
      );
      if (response.statusCode == 200) {
        final u = jsonDecode(response.body);
        firstName.value = u['firstName'] ?? '';
        lastName.value  = u['lastName']  ?? '';
        isAdmin.value   = u['isAdmin']   ?? false;

        emailVerified.value = u['emailVerified'] ?? false;
        pwdCardVerificationStatus.value =
            u['pwdCardVerificationStatus'] ?? 'unverified';
        pwdCardRejectionReason.value =
            u['pwdCardRejectionReason'] ?? '';

        if (u['age'] != null && u['location'] != null && u['disabilityType'] != null) {
          profileCompleted.value = true;

          age.value = (u['age'] is int)
              ? u['age'] : int.tryParse(u['age'].toString()) ?? 0;
          income.value = (u['income'] is int)
              ? u['income'] : int.tryParse(u['income'].toString()) ?? 0;
          householdSize.value = (u['householdSize'] is int)
              ? u['householdSize'] : int.tryParse(u['householdSize'].toString()) ?? 0;

          location.value         = u['location']         ?? '';
          employmentStatus.value = u['employmentStatus'] ?? '';
          educationLevel.value   = u['educationLevel']   ?? '';
          citizenshipStatus.value = u['citizenshipStatus'] ?? '';
          disabilityType.value   = u['disabilityType']   ?? '';
          disabilityStatus.value = u['disabilityStatus'] ?? false;
          pwdCardStatus.value    = u['pwdCardStatus']    ?? false;
          pwdCardNumber.value    = u['pwdCardNumber']    ?? '';
          pwdCardImageUrl.value  = u['pwdCardImageUrl']  ?? '';
          disabilities.value     = List<String>.from(u['disabilities'] ?? []);
          isStudent.value        = u['isStudent']        ?? false;
          applicantType.value    = u['applicantType']    ?? 'Self';
          caretakerName.value         = u['caretakerName']         ?? '';
          caretakerRelationship.value = u['caretakerRelationship'] ?? '';
          caretakerPhone.value        = u['caretakerPhone']        ?? '';
          caretakerNationalId.value   = u['caretakerNationalId']   ?? '';
        } else {
          profileCompleted.value = false;
        }
      }
    } catch (error) {
      debugPrint('Error checking profile status: $error');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  void clearSession() async {
    await _clearToken();
    isSignedIn.value         = false;
    isAdmin.value            = false;
    signedEmail.value        = '';
    firstName.value          = '';
    lastName.value           = '';
    age.value                = 0;
    location.value           = '';
    income.value             = 0;
    householdSize.value      = 0;
    employmentStatus.value   = '';
    educationLevel.value     = '';
    citizenshipStatus.value  = '';
    disabilityType.value     = '';
    disabilityStatus.value   = false;
    pwdCardStatus.value      = false;
    pwdCardNumber.value      = '';
    pwdCardImageUrl.value    = '';
    pwdCardVerificationStatus.value = 'unverified';
    pwdCardRejectionReason.value    = '';
    emailVerified.value      = false;
    disabilities.clear();
    isStudent.value          = false;
    applicantType.value      = '';
    caretakerName.value      = '';
    caretakerRelationship.value = '';
    caretakerPhone.value     = '';
    caretakerNationalId.value = '';
    profileCompleted.value   = false;
  }

  bool canAccessMatching() => isSignedIn.value && profileCompleted.value;

  String getUserSummary() {
    if (!profileCompleted.value) return 'Complete your profile to find matching programs';
    final pwdText = pwdCardStatus.value ? 'PWD Card ✓' : 'No PWD Card';
    final applicantText = isCaretakerApplication
        ? 'Applied by: ${caretakerName.value} (${caretakerRelationship.value})'
        : 'Self-application';
    return '${age.value} yrs • ${location.value} • ${disabilityType.value} • $pwdText\n$applicantText';
  }

  // ── Static lists ──────────────────────────────────────────────────────────
  static const List<String> applicantTypes = ['Self', 'Caretaker'];

  static const List<String> caretakerRelationships = [
    'Parent', 'Sibling', 'Spouse / Partner', 'Child',
    'Relative', 'NGO / Social Worker', 'Legal Guardian', 'Other',
  ];

  static const List<String> disabilityTypes = [
    'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment',
    'Intellectual / Cognitive', 'Mental Health', 'Multiple Disabilities', 'Other',
  ];

  static const List<String> employmentStatuses = [
    'Employed', 'Self-Employed', 'Unemployed', 'Student', 'Retired', 'Unable to Work',
  ];

  static const List<String> educationLevels = [
    'None', 'Primary', 'Secondary', 'Certificate / Diploma',
    'Undergraduate', 'Postgraduate',
  ];

  static const List<String> kenyaCounties = [
    'Baringo', 'Bomet', 'Bungoma', 'Busia', 'Elgeyo-Marakwet',
    'Embu', 'Garissa', 'Homa Bay', 'Isiolo', 'Kajiado',
    'Kakamega', 'Kericho', 'Kiambu', 'Kilifi', 'Kirinyaga',
    'Kisii', 'Kisumu', 'Kitui', 'Kwale', 'Laikipia',
    'Lamu', 'Machakos', 'Makueni', 'Mandera', 'Marsabit',
    'Meru', 'Migori', 'Mombasa', "Murang'a", 'Nairobi',
    'Nakuru', 'Nandi', 'Narok', 'Nyamira', 'Nyandarua',
    'Nyeri', 'Samburu', 'Siaya', 'Taita-Taveta', 'Tana River',
    'Tharaka-Nithi', 'Trans Nzoia', 'Turkana', 'Uasin Gishu',
    'Vihiga', 'Wajir', 'West Pokot',
  ];
}