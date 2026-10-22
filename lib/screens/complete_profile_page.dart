import 'dart:convert';
import 'package:aidlinkapp/utilities/auth_controller.dart';
import 'package:aidlinkapp/utilities/base_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final ageController              = TextEditingController();
  final incomeController           = TextEditingController();
  final householdSizeController    = TextEditingController();
  final pwdCardNumberController    = TextEditingController();
  final caretakerNameController    = TextEditingController();
  final caretakerPhoneController   = TextEditingController();
  final caretakerNationalIdController = TextEditingController();

  String? selectedApplicantType;
  String? selectedCaretakerRelationship;
  String? selectedLocation;
  String? selectedEmploymentStatus;
  String? selectedEducationLevel;
  String? selectedCitizenshipStatus;
  String? selectedDisabilityType;
  bool disabilityStatus = false;
  bool pwdCardStatus    = false;
  bool isStudent        = false;
  List<String> selectedDisabilities = [];

  Uint8List? _pwdCardImageBytes;
  String?   _uploadedPwdCardImageUrl;
  bool      _uploadingImage = false;

  RxString savingStatus = ''.obs;

  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
  }

  void _prefillFromAuth() {
    if (!auth.profileCompleted.value) return;
    if (auth.age.value > 0) ageController.text = auth.age.value.toString();
    if (auth.income.value > 0) incomeController.text = auth.income.value.toString();
    if (auth.householdSize.value > 0) householdSizeController.text = auth.householdSize.value.toString();
    if (auth.pwdCardNumber.value.isNotEmpty) pwdCardNumberController.text = auth.pwdCardNumber.value;
    if (auth.caretakerName.value.isNotEmpty) caretakerNameController.text = auth.caretakerName.value;
    if (auth.caretakerPhone.value.isNotEmpty) caretakerPhoneController.text = auth.caretakerPhone.value;
    if (auth.caretakerNationalId.value.isNotEmpty) caretakerNationalIdController.text = auth.caretakerNationalId.value;
    if (auth.pwdCardImageUrl.value.isNotEmpty) _uploadedPwdCardImageUrl = auth.pwdCardImageUrl.value;
    setState(() {
      if (auth.applicantType.value.isNotEmpty) selectedApplicantType = auth.applicantType.value;
      if (auth.caretakerRelationship.value.isNotEmpty) selectedCaretakerRelationship = auth.caretakerRelationship.value;
      if (auth.location.value.isNotEmpty) selectedLocation = auth.location.value;
      if (auth.employmentStatus.value.isNotEmpty) selectedEmploymentStatus = auth.employmentStatus.value;
      if (auth.educationLevel.value.isNotEmpty) selectedEducationLevel = auth.educationLevel.value;
      if (auth.citizenshipStatus.value.isNotEmpty) selectedCitizenshipStatus = auth.citizenshipStatus.value;
      if (auth.disabilityType.value.isNotEmpty) selectedDisabilityType = auth.disabilityType.value;
      disabilityStatus      = auth.disabilityStatus.value;
      pwdCardStatus         = auth.pwdCardStatus.value;
      isStudent             = auth.isStudent.value;
      selectedDisabilities  = List<String>.from(auth.disabilities);
    });
  }

  @override
  void dispose() {
    ageController.dispose();
    incomeController.dispose();
    householdSizeController.dispose();
    pwdCardNumberController.dispose();
    caretakerNameController.dispose();
    caretakerPhoneController.dispose();
    caretakerNationalIdController.dispose();
    super.dispose();
  }

  Future<void> _pickPwdCardImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _pwdCardImageBytes = bytes; _uploadedPwdCardImageUrl = null; });
    await _uploadPwdCardImage(picked);
  }

  Future<void> _uploadPwdCardImage(XFile picked) async {
    if (_pwdCardImageBytes == null) return;
    setState(() => _uploadingImage = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/users/upload-pwd-card'));
      request.headers['x-auth-token'] = auth.token.value;
      request.files.add(http.MultipartFile.fromBytes('pwdCard', _pwdCardImageBytes!, filename: picked.name));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        setState(() => _uploadedPwdCardImageUrl = json['url'] ?? json['imageUrl']);
        Get.snackbar('Uploaded!', 'PWD card image saved successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Upload failed', 'Could not upload image — try again',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Upload error: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Upload PWD Card Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Take a clear photo of both sides of your PWD card',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xff164EB0),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20)),
              title: const Text('Take a photo'),
              subtitle: const Text('Use your camera'),
              onTap: () { Get.back(); _pickPwdCardImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.teal,
                  child: Icon(Icons.photo_library, color: Colors.white, size: 20)),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Select an existing photo'),
              onTap: () { Get.back(); _pickPwdCardImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Profile summary panel (right side) ───────────────────────────────────
  Widget _profileSummaryPanel(bool isDark) {
    final hasProfile  = auth.profileCompleted.value;
    final panelBg     = isDark ? const Color(0xff1a2436) : const Color(0xfff7f9ff);
    final borderColor = isDark ? const Color(0xff374151) : Colors.grey.shade200;
    final labelColor  = isDark ? const Color(0xff94a3b8) : Colors.grey[500]!;
    final valueColor  = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(left: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            color: const Color(0xff164EB0),
            child: Row(children: [
              const Icon(Icons.person_pin_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(hasProfile ? 'Your Current Profile' : 'Profile Preview',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              if (hasProfile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Complete',
                      style: TextStyle(color: Colors.white, fontSize: 9)),
                ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: hasProfile
                  ? _buildProfileRows(isDark, labelColor, valueColor)
                  : _buildEmptyProfile(isDark, labelColor, valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProfile(bool isDark, Color labelColor, Color valueColor) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.account_circle_outlined,
            size: 60,
            color: isDark ? const Color(0xff374151) : Colors.grey[300]),
        const SizedBox(height: 12),
        Text('No profile yet',
            style: TextStyle(
                color: isDark ? const Color(0xff94a3b8) : Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text('Fill in the form on the left\nto set up your profile',
            style: TextStyle(
                color: isDark ? const Color(0xff64748b) : Colors.grey[400],
                fontSize: 11),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _livePreviewHint(isDark, labelColor, valueColor),
      ],
    );
  }

  Widget _livePreviewHint(bool isDark, Color labelColor, Color valueColor) {
    final hasAnyInput = selectedApplicantType != null ||
        selectedDisabilityType != null ||
        ageController.text.isNotEmpty ||
        selectedLocation != null;
    if (!hasAnyInput) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xff164EB0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(children: [
            Icon(Icons.visibility_outlined, size: 13, color: Color(0xff164EB0)),
            SizedBox(width: 6),
            Text('Live preview',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff164EB0),
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 10),
        _buildProfileRows(isDark, labelColor, valueColor),
      ],
    );
  }

  Widget _buildProfileRows(bool isDark, Color labelColor, Color valueColor) {
    final liveAge       = ageController.text.isNotEmpty ? ageController.text : (auth.age.value > 0 ? '${auth.age.value}' : null);
    final liveIncome    = incomeController.text.isNotEmpty ? 'KES ${incomeController.text}' : (auth.income.value > 0 ? 'KES ${auth.income.value}' : null);
    final liveHousehold = householdSizeController.text.isNotEmpty ? '${householdSizeController.text} people' : (auth.householdSize.value > 0 ? '${auth.householdSize.value} people' : null);
    final livePwdCard   = pwdCardNumberController.text.isNotEmpty ? pwdCardNumberController.text : (auth.pwdCardNumber.value.isNotEmpty ? auth.pwdCardNumber.value : null);
    final liveApplicant      = selectedApplicantType     ?? auth.applicantType.value;
    final liveCitizenship    = selectedCitizenshipStatus ?? auth.citizenshipStatus.value;
    final liveLocation       = selectedLocation          ?? auth.location.value;
    final liveDisabilityType = selectedDisabilityType    ?? auth.disabilityType.value;
    final liveEmployment     = selectedEmploymentStatus  ?? auth.employmentStatus.value;
    final liveEducation      = selectedEducationLevel    ?? auth.educationLevel.value;
    final liveNCPWD          = disabilityStatus || auth.disabilityStatus.value;
    final livePwdCardStatus  = pwdCardStatus    || auth.pwdCardStatus.value;
    final liveIsStudent      = isStudent        || auth.isStudent.value;
    final liveDisabilities   = selectedDisabilities.isNotEmpty ? selectedDisabilities : List<String>.from(auth.disabilities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Identity', isDark),
        _infoRow(Icons.person_outline,   'Applicant Type', liveApplicant,   labelColor, valueColor),
        _infoRow(Icons.flag_outlined,    'Citizenship',    liveCitizenship, labelColor, valueColor),
        _infoRow(Icons.cake_outlined,    'Age',            liveAge,         labelColor, valueColor),
        _infoRow(Icons.location_on_outlined, 'County',     liveLocation,    labelColor, valueColor),
        _infoRow(Icons.home_outlined,    'Household Size', liveHousehold,   labelColor, valueColor),
        const SizedBox(height: 10),
        _sectionLabel('Disability', isDark),
        _infoRow(Icons.accessible_outlined, 'Disability Type', liveDisabilityType, labelColor, valueColor),
        _infoBadge('Registered with NCPWD', liveNCPWD, isDark),
        _infoBadge('Has PWD Card', livePwdCardStatus, isDark),
        if (livePwdCardStatus && livePwdCard != null)
          _infoRow(Icons.credit_card_outlined, 'Card Number', livePwdCard, labelColor, valueColor),
        if (livePwdCardStatus && _uploadedPwdCardImageUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(children: [
              const Icon(Icons.verified, color: Colors.green, size: 12),
              const SizedBox(width: 4),
              const Text('Card photo uploaded ✓',
                  style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)),
            ]),
          ),
        if (liveDisabilities.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Additional disabilities:',
              style: TextStyle(fontSize: 9, color: labelColor)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4, runSpacing: 4,
            children: liveDisabilities.map((d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xff164EB0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(d,
                  style: const TextStyle(fontSize: 9, color: Color(0xff164EB0))),
            )).toList(),
          ),
        ],
        const SizedBox(height: 10),
        _sectionLabel('Employment & Financial', isDark),
        _infoRow(Icons.work_outline,     'Employment', liveEmployment, labelColor, valueColor),
        _infoRow(Icons.school_outlined,  'Education',  liveEducation,  labelColor, valueColor),
        _infoBadge('Currently a student', liveIsStudent, isDark),
        _infoRow(Icons.payments_outlined, 'Monthly Income', liveIncome, labelColor, valueColor),
        if (liveApplicant == 'Caretaker') ...[
          const SizedBox(height: 10),
          _sectionLabel('Caretaker Details', isDark),
          _infoRow(Icons.person_outline, 'Caretaker Name',
              caretakerNameController.text.isNotEmpty ? caretakerNameController.text : auth.caretakerName.value,
              labelColor, valueColor),
          _infoRow(Icons.phone_outlined, 'Phone',
              caretakerPhoneController.text.isNotEmpty ? caretakerPhoneController.text : auth.caretakerPhone.value,
              labelColor, valueColor),
          _infoRow(Icons.badge_outlined, 'National ID',
              caretakerNationalIdController.text.isNotEmpty ? caretakerNationalIdController.text : auth.caretakerNationalId.value,
              labelColor, valueColor),
          _infoRow(Icons.people_outline, 'Relationship',
              selectedCaretakerRelationship ?? auth.caretakerRelationship.value,
              labelColor, valueColor),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xff164EB0),
                letterSpacing: 0.8)),
        const SizedBox(width: 6),
        Expanded(
            child: Divider(
                color: const Color(0xff164EB0).withValues(alpha: 0.2),
                thickness: 1)),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value,
      Color labelColor, Color valueColor) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 12, color: labelColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 9, color: labelColor)),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _infoBadge(String label, bool isTrue, bool isDark) {
    final activeColor = isDark ? Colors.white : Colors.black87;
    final inactiveColor = isDark ? const Color(0xff4b5563) : Colors.grey[400]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(isTrue ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color: isTrue ? Colors.green : inactiveColor),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isTrue ? activeColor : inactiveColor,
                fontWeight: isTrue ? FontWeight.w600 : FontWeight.normal)),
      ]),
    );
  }

  // ── Step widgets ──────────────────────────────────────────────────────────
  Widget _stepApplicantType(Color titleColor, Color bodyColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is filling this form?',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
        const SizedBox(height: 16),
        ...AuthController.applicantTypes.map((type) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                type == 'Self'
                    ? 'Myself (Person with Disability)'
                    : 'I am a Caretaker / Guardian',
                style: TextStyle(fontSize: 14, color: titleColor),
              ),
              subtitle: Text(
                type == 'Self'
                    ? 'I have a disability and applying for myself'
                    : 'Applying on behalf of someone with a disability',
                style: TextStyle(fontSize: 12, color: bodyColor),
              ),
              value: type,
              groupValue: selectedApplicantType,
              activeColor: const Color(0xff164EB0),
              onChanged: (val) => setState(() => selectedApplicantType = val),
            )),
        if (selectedApplicantType == 'Caretaker') ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Caretaker Details',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                  fontSize: 14)),
          const SizedBox(height: 16),
          TextFormField(
            controller: caretakerNameController,
            decoration: const InputDecoration(
                labelText: 'Your Full Name (Caretaker)',
                prefixIcon: Icon(Icons.person_outline),
                isDense: true),
            onChanged: (_) => setState(() {}),
            validator: (v) => selectedApplicantType == 'Caretaker' &&
                    (v == null || v.isEmpty)
                ? 'Please enter caretaker name'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: caretakerNationalIdController,
            decoration: InputDecoration(
              labelText: 'Kenya National ID Number',
              hintText: 'e.g. 12345678',
              helperText: 'Valid Kenyan National ID (7–8 digits)',
              prefixIcon: const Icon(Icons.badge_outlined),
              isDense: true,
              suffixIcon: caretakerNationalIdController.text.isNotEmpty
                  ? Icon(
                      AuthController.validateKenyanNationalId(
                                  caretakerNationalIdController.text) ==
                              null
                          ? Icons.check_circle
                          : Icons.error,
                      color: AuthController.validateKenyanNationalId(
                                  caretakerNationalIdController.text) ==
                              null
                          ? Colors.green
                          : Colors.red,
                      size: 18)
                  : null,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8)
            ],
            onChanged: (_) => setState(() {}),
            validator: (v) => selectedApplicantType == 'Caretaker'
                ? AuthController.validateKenyanNationalId(v)
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedCaretakerRelationship,
            decoration: const InputDecoration(
                labelText: 'Relationship to the PWD',
                prefixIcon: Icon(Icons.people_outline),
                isDense: true),
            items: AuthController.caretakerRelationships
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) =>
                setState(() => selectedCaretakerRelationship = val),
            validator: (v) =>
                selectedApplicantType == 'Caretaker' && v == null
                    ? 'Please select relationship'
                    : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: caretakerPhoneController,
            decoration: const InputDecoration(
                labelText: 'Your Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                isDense: true),
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _stepDisabilityInfo(Color titleColor, Color bodyColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Disability Information',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedDisabilityType,
          decoration: const InputDecoration(
              labelText: 'Type of Disability',
              prefixIcon: Icon(Icons.accessible_outlined),
              isDense: true),
          items: AuthController.disabilityTypes
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (val) => setState(() => selectedDisabilityType = val),
          validator: (v) =>
              v == null ? 'Please select disability type' : null,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Registered with NCPWD?',
              style: TextStyle(fontSize: 14, color: titleColor)),
          subtitle: Text('Official disability registration',
              style: TextStyle(fontSize: 12, color: bodyColor)),
          value: disabilityStatus,
          activeThumbColor: const Color(0xff164EB0),
          onChanged: (val) => setState(() => disabilityStatus = val),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Do you have a PWD Card?',
              style: TextStyle(fontSize: 14, color: titleColor)),
          subtitle: Text('PWD identification card',
              style: TextStyle(fontSize: 12, color: bodyColor)),
          value: pwdCardStatus,
          activeThumbColor: const Color(0xff164EB0),
          onChanged: (val) => setState(() {
            pwdCardStatus = val;
            if (!val) {
              _pwdCardImageBytes = null;
              _uploadedPwdCardImageUrl = null;
              pwdCardNumberController.clear();
            }
          }),
        ),
        if (pwdCardStatus) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: pwdCardNumberController,
            decoration: const InputDecoration(
                labelText: 'PWD Card Number',
                hintText: 'e.g. NCPWD/P/123456',
                prefixIcon: Icon(Icons.credit_card_outlined),
                isDense: true),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              if (!RegExp(r'^NCPWD\/P\/\d+$').hasMatch(v.trim()))
                return 'Use format: NCPWD/P/123456';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _uploadedPwdCardImageUrl != null
                      ? Colors.green
                      : Colors.orange.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(10),
              color: _uploadedPwdCardImageUrl != null
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.orange.withValues(alpha: 0.04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    _uploadedPwdCardImageUrl != null
                        ? Icons.verified
                        : Icons.upload_file_outlined,
                    color: _uploadedPwdCardImageUrl != null
                        ? Colors.green
                        : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _uploadedPwdCardImageUrl != null
                          ? 'Card Photo Uploaded ✓'
                          : 'Upload PWD Card Photo (Required)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _uploadedPwdCardImageUrl != null
                              ? Colors.green
                              : Colors.orange),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text('Clear photo of your PWD card front side',
                    style: TextStyle(fontSize: 12, color: bodyColor)),
                const SizedBox(height: 10),
                if (_pwdCardImageBytes != null) ...[
                  ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(_pwdCardImageBytes!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover)),
                  const SizedBox(height: 8),
                ] else if (_uploadedPwdCardImageUrl != null) ...[
                  ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(_uploadedPwdCardImageUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink())),
                  const SizedBox(height: 8),
                ],
                _uploadingImage
                    ? const Row(children: [
                        SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Uploading...',
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey)),
                      ])
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: Icon(
                              _uploadedPwdCardImageUrl != null
                                  ? Icons.refresh
                                  : Icons.camera_alt_outlined,
                              size: 14),
                          label: Text(
                              _uploadedPwdCardImageUrl != null
                                  ? 'Replace Photo'
                                  : 'Upload Card Photo',
                              style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            foregroundColor: _uploadedPwdCardImageUrl != null
                                ? Colors.green
                                : const Color(0xff164EB0),
                            side: BorderSide(
                                color: _uploadedPwdCardImageUrl != null
                                    ? Colors.green
                                    : const Color(0xff164EB0)),
                          ),
                          onPressed: _showImageSourceSheet,
                        ),
                      ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('Additional disabilities (if any):',
            style: TextStyle(fontSize: 13, color: bodyColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: AuthController.disabilityTypes.map((d) {
            final selected = selectedDisabilities.contains(d);
            return FilterChip(
              label: Text(d, style: const TextStyle(fontSize: 12)),
              selected: selected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              selectedColor:
                  const Color(0xff164EB0).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xff164EB0),
              onSelected: (val) => setState(() {
                if (val) {
                  selectedDisabilities.add(d);
                } else {
                  selectedDisabilities.remove(d);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepPersonalInfo(Color titleColor, Color bodyColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Information',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
        const SizedBox(height: 16),
        TextFormField(
          controller: ageController,
          decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake_outlined),
              isDense: true),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter age';
            final age = int.tryParse(v);
            if (age == null || age < 1 || age > 120)
              return 'Enter a valid age';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedLocation,
          decoration: const InputDecoration(
              labelText: 'County / Location',
              prefixIcon: Icon(Icons.location_on_outlined),
              isDense: true),
          items: AuthController.kenyaCounties
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) => setState(() => selectedLocation = val),
          validator: (v) =>
              v == null ? 'Please select your county' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedCitizenshipStatus,
          decoration: const InputDecoration(
              labelText: 'Citizenship Status',
              prefixIcon: Icon(Icons.flag_outlined),
              isDense: true),
          items: const [
            DropdownMenuItem(
                value: 'Kenyan Citizen', child: Text('Kenyan Citizen')),
            DropdownMenuItem(
                value: 'Non-Citizen', child: Text('Non-Citizen')),
          ],
          onChanged: (val) =>
              setState(() => selectedCitizenshipStatus = val),
          validator: (v) =>
              v == null ? 'Please select citizenship status' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: householdSizeController,
          decoration: const InputDecoration(
              labelText: 'Household Size',
              prefixIcon: Icon(Icons.home_outlined),
              hintText: 'Number of people in household',
              isDense: true),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter household size';
            final size = int.tryParse(v);
            if (size == null || size < 1) return 'Enter a valid number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _stepFinancialInfo(Color titleColor, Color bodyColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financial & Employment',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
        const SizedBox(height: 16),
        TextFormField(
          controller: incomeController,
          decoration: const InputDecoration(
              labelText: 'Monthly Income (KES)',
              prefixIcon: Icon(Icons.payments_outlined),
              hintText: 'Enter 0 if unemployed',
              isDense: true),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          validator: (v) => v == null || v.isEmpty
              ? 'Please enter income (0 if none)'
              : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedEmploymentStatus,
          decoration: const InputDecoration(
              labelText: 'Employment Status',
              prefixIcon: Icon(Icons.work_outline),
              isDense: true),
          items: AuthController.employmentStatuses
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() {
            selectedEmploymentStatus = val;
            if (val == 'Student') isStudent = true;
          }),
          validator: (v) =>
              v == null ? 'Please select employment status' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedEducationLevel,
          decoration: const InputDecoration(
              labelText: 'Highest Education Level',
              prefixIcon: Icon(Icons.school_outlined),
              isDense: true),
          items: AuthController.educationLevels
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => selectedEducationLevel = val),
          validator: (v) =>
              v == null ? 'Please select education level' : null,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Currently a Student?',
              style: TextStyle(fontSize: 14, color: titleColor)),
          value: isStudent,
          activeThumbColor: const Color(0xff164EB0),
          onChanged: (val) => setState(() => isStudent = val),
        ),
      ],
    );
  }

  // ── Save Profile ──────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (pwdCardStatus && _uploadedPwdCardImageUrl == null) {
      Get.snackbar('PWD Card Photo Required',
          'Please upload a photo of your PWD card before saving',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    setState(() => savingStatus.value = 'saving');
    final result = await auth.completeProfile(
      age: int.parse(ageController.text),
      location: selectedLocation!,
      income: int.parse(incomeController.text),
      householdSize: int.parse(householdSizeController.text),
      employmentStatus: selectedEmploymentStatus!,
      educationLevel: selectedEducationLevel!,
      citizenshipStatus: selectedCitizenshipStatus!,
      disabilityType: selectedDisabilityType!,
      disabilityStatus: disabilityStatus,
      pwdCardStatus: pwdCardStatus,
      pwdCardNumber: pwdCardNumberController.text.isNotEmpty
          ? pwdCardNumberController.text
          : null,
      pwdCardImageUrl: _uploadedPwdCardImageUrl,
      disabilities: selectedDisabilities,
      isStudent: isStudent,
      applicantType: selectedApplicantType!,
      caretakerName: selectedApplicantType == 'Caretaker'
          ? caretakerNameController.text
          : null,
      caretakerRelationship: selectedApplicantType == 'Caretaker'
          ? selectedCaretakerRelationship
          : null,
      caretakerPhone: selectedApplicantType == 'Caretaker'
          ? caretakerPhoneController.text
          : null,
      caretakerNationalId: selectedApplicantType == 'Caretaker'
          ? caretakerNationalIdController.text
          : null,
    );
    if (result == 'success') {
      Get.back();
      Get.snackbar(
        auth.profileCompleted.value ? 'Profile Updated!' : 'Profile Complete!',
        'Your profile has been saved. Finding your matches...',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      setState(() => savingStatus.value = '');
      Get.snackbar('Error', result,
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0 && selectedApplicantType == null) {
      Get.snackbar('Required', 'Please select who is applying',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }
    if (_currentStep == 1 && selectedDisabilityType == null) {
      Get.snackbar('Required', 'Please select disability type',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }
    if (_currentStep == 1 &&
        pwdCardStatus &&
        _uploadedPwdCardImageUrl == null) {
      Get.snackbar('Upload Required',
          'Please upload a photo of your PWD card to continue',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }
    return _formKey.currentState?.validate() ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDark ? const Color(0xff111827) : Colors.white;
    final formBg     = isDark ? const Color(0xff111827) : Colors.white;
    final stepBg     = isDark ? const Color(0xff1f2937) : Colors.grey[100]!;
    final navBg      = isDark ? const Color(0xff1f2937) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xff111827);
    final bodyColor  = isDark ? const Color(0xffcbd5e1) : const Color(0xff374151);
    final divColor   = isDark ? const Color(0xff374151) : Colors.grey.withValues(alpha: 0.1);

    final steps = ['Applicant Type', 'Disability Info', 'Personal Info', 'Financial Info'];
    final stepWidgets = [
      _stepApplicantType(titleColor, bodyColor),
      _stepDisabilityInfo(titleColor, bodyColor),
      _stepPersonalInfo(titleColor, bodyColor),
      _stepFinancialInfo(titleColor, bodyColor),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Obx(() => Text(
            auth.profileCompleted.value ? 'Edit Profile' : 'Complete Your Profile')),
        backgroundColor: const Color(0xff164EB0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() => savingStatus.value == 'saving'
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving your profile...',
                    style: TextStyle(color: titleColor)),
              ]))
          : Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: form ─────────────────────────────────────────
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Step indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          color: stepBg,
                          child: Row(
                            children: List.generate(steps.length, (i) {
                              final isActive = i == _currentStep;
                              final isDone   = i < _currentStep;
                              return Expanded(
                                child: Row(children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: isDone
                                              ? Colors.green
                                              : isActive
                                                  ? const Color(0xff164EB0)
                                                  : (isDark
                                                      ? const Color(0xff374151)
                                                      : Colors.grey[300]),
                                          child: isDone
                                              ? const Icon(Icons.check,
                                                  color: Colors.white,
                                                  size: 13)
                                              : Text('${i + 1}',
                                                  style: TextStyle(
                                                      color: isActive
                                                          ? Colors.white
                                                          : (isDark
                                                              ? Colors.grey[500]
                                                              : Colors.grey),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(steps[i],
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: isActive
                                                    ? const Color(0xff164EB0)
                                                    : (isDark
                                                        ? Colors.grey[500]
                                                        : Colors.grey),
                                                fontWeight: isActive
                                                    ? FontWeight.bold
                                                    : FontWeight.normal),
                                            textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                  if (i < steps.length - 1)
                                    Expanded(
                                      child: Divider(
                                          color: isDone
                                              ? Colors.green
                                              : (isDark
                                                  ? const Color(0xff374151)
                                                  : Colors.grey[300]),
                                          thickness: 1.5),
                                    ),
                                ]),
                              );
                            }),
                          ),
                        ),

                        // Step content
                        Expanded(
                          child: Container(
                            color: formBg,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              child: stepWidgets[_currentStep],
                            ),
                          ),
                        ),

                        // Navigation buttons
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: navBg,
                            boxShadow: [
                              BoxShadow(
                                  color: divColor,
                                  blurRadius: 6,
                                  offset: const Offset(0, -2))
                            ],
                          ),
                          child: Row(children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    foregroundColor: isDark
                                        ? Colors.white70
                                        : const Color(0xff164EB0),
                                    side: BorderSide(
                                        color: isDark
                                            ? const Color(0xff4b5563)
                                            : const Color(0xff164EB0)),
                                  ),
                                  child: const Text('Back'),
                                ),
                              ),
                            if (_currentStep > 0) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff164EB0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                ),
                                onPressed: () {
                                  if (!_validateCurrentStep()) return;
                                  if (_currentStep < steps.length - 1) {
                                    setState(() => _currentStep++);
                                  } else {
                                    _saveProfile();
                                  }
                                },
                                child: Text(_currentStep < steps.length - 1
                                    ? 'Next'
                                    : auth.profileCompleted.value
                                        ? 'Update Profile'
                                        : 'Save Profile'),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),

                  // ── RIGHT: profile summary panel ───────────────────────
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          MediaQuery.of(context).padding.top,
                      child: _profileSummaryPanel(isDark),
                    ),
                  ),
                ],
              ),
            )),
    );
  }
}