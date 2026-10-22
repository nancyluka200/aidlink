import 'package:aidlinkapp/utilities/auth_controller.dart';

// ── Aid Program ───────────────────────────────────────────────────────────────
class AidProgram {
  final String id;
  final String name;
  final String organization;
  final String category;
  final String description;
  final String websiteUrl;
  final String contactInfo;
  final List<String> requiredDocuments;
  final String? deadline;
  final String howToApply;

  const AidProgram({
    required this.id,
    required this.name,
    required this.organization,
    required this.category,
    required this.description,
    required this.websiteUrl,
    required this.contactInfo,
    required this.requiredDocuments,
    this.deadline,
    required this.howToApply,
  });
}

// ── Match Result ──────────────────────────────────────────────────────────────
class MatchResult {
  final AidProgram program;
  final int matchScore;
  final List<String> matchReasons;
  final List<String> missingRequirements;
  final bool fullyEligible;

  const MatchResult({
    required this.program,
    required this.matchScore,
    required this.matchReasons,
    required this.missingRequirements,
    required this.fullyEligible,
  });

  // ── FIX: matchLabel is now based on fullyEligible + score together ─────────
  // A program is only a "Strong Match" if the user meets ALL requirements
  // (no missing requirements, no critical missing). Score alone is NOT enough.
  String get matchLabel {
    if (fullyEligible) {
      if (matchScore >= 80) return 'Strong Match';
      return 'Good Match';
    }
    // Has missing requirements → always partial regardless of score
    if (matchScore >= 60) return 'Partial Match';
    if (matchScore >= 40) return 'Low Match';
    return 'Low Match';
  }
}

// ── Match Output ──────────────────────────────────────────────────────────────
class MatchOutput {
  final MatchResult topMatch;
  final List<MatchResult> suggestions;

  const MatchOutput({
    required this.topMatch,
    required this.suggestions,
  });
}

// ── Kenya Disability Programs Database ───────────────────────────────────────
class ProgramsDatabase {
  static const List<AidProgram> programs = [
    AidProgram(
      id: 'ncpwd_cash_transfer',
      name: 'NCPWD Cash Transfer Program',
      organization: 'National Council for Persons with Disabilities (NCPWD)',
      category: 'Cash Transfer',
      description:
          'Monthly cash transfers to vulnerable persons with disabilities to support basic needs and improve livelihoods.',
      websiteUrl: 'https://ncpwd.ecitizen.go.ke',
      contactInfo: 'Tel: 020-3554248 | Email: info@ncpwd.go.ke',
      requiredDocuments: [
        'National ID or Birth Certificate',
        'PWD Card (mandatory)',
        'Proof of disability (medical certificate)',
        'Bank account details or M-Pesa number',
        'Recent passport photo',
      ],
      howToApply:
          'Visit your nearest NCPWD county office or apply online at ncpwd.ecitizen.go.ke. You must have a valid PWD card.',
    ),
    AidProgram(
      id: 'ncpwd_assistive_devices',
      name: 'NCPWD Assistive Devices Program',
      organization: 'National Council for Persons with Disabilities (NCPWD)',
      category: 'Assistive Devices',
      description:
          'Provision of wheelchairs, hearing aids, white canes, prosthetics, and other assistive devices to persons with disabilities.',
      websiteUrl: 'https://ncpwd.go.ke/ndfpwd-application-forms/',
      contactInfo: 'Tel: 020-3554248 | Email: info@ncpwd.go.ke',
      requiredDocuments: [
        'National ID or Birth Certificate',
        'PWD Card',
        'Medical assessment report recommending the device',
        'Recent passport photo',
      ],
      howToApply:
          'Download the NDFPWD application form from ncpwd.go.ke/ndfpwd-application-forms or collect from any NCPWD office. Submit with a medical assessment report.',
    ),
    AidProgram(
      id: 'ncpwd_education',
      name: 'NCPWD Education Bursary & Scholarships',
      organization: 'National Council for Persons with Disabilities (NCPWD)',
      category: 'Education',
      description:
          'Bursaries and scholarships for learners with disabilities at secondary, tertiary, and university levels.',
      websiteUrl: 'https://ncpwd.go.ke/ndfpwd-application-forms/',
      contactInfo: 'Tel: 020-3554248 | Email: info@ncpwd.go.ke',
      requiredDocuments: [
        'National ID or Birth Certificate',
        'PWD Card',
        'Admission letter from institution',
        'Most recent academic results',
        'Fee structure from institution',
        'Recommendation letter',
      ],
      deadline: 'Applications open annually — check ncpwd.go.ke for current dates',
      howToApply:
          'Download the bursary form from ncpwd.go.ke/ndfpwd-application-forms or collect from NCPWD offices. Submit during the open application period.',
    ),
    AidProgram(
      id: 'nsnp_pwsd_ct',
      name: 'Persons with Severe Disabilities Cash Transfer (PWSD-CT)',
      organization: 'National Safety Net Programme (NSNP) – Ministry of Labour',
      category: 'Cash Transfer',
      description:
          'Regular cash transfers of KES 2,000/month to households caring for persons with severe disabilities who require full-time assistance.',
      websiteUrl: 'https://www.labour.go.ke',
      contactInfo:
          'Ministry of Labour: 020-2729800 | Contact your Sub-County Social Development Officer',
      requiredDocuments: [
        'National ID of PWD and caretaker',
        'PWD Card',
        'Proof of severe disability (medical certificate)',
        'Proof of residence',
        'Poverty assessment by local welfare committee',
        'Confirmation of non-enrollment in other cash transfer programs',
      ],
      howToApply:
          'Physical application only — no online portal. Visit your Sub-County Social Development Officer or local Chief\'s office. Eligibility assessed by a local welfare committee.',
    ),
    AidProgram(
      id: 'nfdk_tools',
      name: 'NFDK Tools of Trade & Assistive Devices',
      organization: 'National Fund for the Disabled of Kenya (NFDK)',
      category: 'Assistive Devices',
      description:
          'Provides tools of trade (sewing machines, welding equipment, barber kits) and mobility aids to promote economic self-reliance for PWDs.',
      websiteUrl: 'https://nfdk.or.ke',
      contactInfo: 'Tel: 020-2215390 | Rehema House, Kaunda/Standard Street, Nairobi',
      requiredDocuments: [
        'National ID',
        'PWD Card',
        'Completed NFDK Form B (from nfdk.or.ke or County Commissioner\'s office)',
        'Recommendation from Area Assistant-Chief',
        'Endorsement from Sub-County Social Protection Officer',
        'Proof of vocational training or trade skill',
        'Recent passport photo',
      ],
      howToApply:
          'Download NFDK Form B from nfdk.or.ke or collect from your County Commissioner\'s office. Get endorsements from your Area Assistant-Chief and Sub-County Social Protection Officer. Drop completed form at your Deputy County Commissioner\'s office.',
    ),
    AidProgram(
      id: 'ncpwd_employment',
      name: 'NCPWD Employment & Vocational Training',
      organization: 'National Council for Persons with Disabilities (NCPWD)',
      category: 'Employment',
      description:
          'Job placement, vocational training, and employment support for persons with disabilities to promote economic inclusion.',
      websiteUrl: 'https://placement.ncpwd.go.ke/public/',
      contactInfo: 'Tel: 020-3554248 | Email: info@ncpwd.go.ke',
      requiredDocuments: [
        'National ID',
        'PWD Card',
        'Academic or professional certificates',
        'CV / Resume',
      ],
      howToApply:
          'Register on the NCPWD Job Placement Portal at placement.ncpwd.go.ke/public/ to access job opportunities. Alternatively, visit any NCPWD County Office in person for vocational training programmes.',
    ),
    AidProgram(
      id: 'ncpwd_legal',
      name: 'NCPWD Legal Advisory Services',
      organization: 'National Council for Persons with Disabilities (NCPWD)',
      category: 'Legal',
      description:
          'Free walk-in legal advice and support on disability rights, discrimination cases, and access to justice for persons with disabilities.',
      websiteUrl: 'https://ncpwd.go.ke',
      contactInfo: 'Tel: 020-3554248 | Email: info@ncpwd.go.ke',
      requiredDocuments: [
        'National ID',
        'Brief written description of legal issue',
      ],
      howToApply:
          'Walk-in service — no appointment needed. Visit the NCPWD Legal Services Department at NCPWD Headquarters, Opposite ABC Place, Waiyaki Way, Nairobi. Monday–Friday 8am–5pm. Free of charge.',
    ),
    AidProgram(
      id: 'county_bursary',
      name: 'County Government Disability Bursary',
      organization: 'County Government (varies by county)',
      category: 'Education',
      description:
          'Education bursaries offered by individual county governments specifically targeting students with disabilities.',
      websiteUrl: 'https://www.cra.go.ke',
      contactInfo:
          'Contact your County Social Services Department or Sub-County Education Office',
      requiredDocuments: [
        'National ID or Birth Certificate',
        'PWD Card (if available)',
        'Admission or enrollment letter',
        'Fee structure',
        'Proof of residence in the county',
      ],
      deadline: 'Varies by county — check your county government website',
      howToApply:
          'Physical application only. Visit your Sub-County Education Office or County Social Services Department. Requirements vary by county.',
    ),
    AidProgram(
      id: 'nhif_disability',
      name: 'SHA Enhanced Benefits for PWDs',
      organization: 'Social Health Authority (SHA) — formerly NHIF',
      category: 'Healthcare',
      description:
          'Enhanced healthcare coverage and exemptions for persons with disabilities including chronic illness management and free services at public hospitals.',
      websiteUrl: 'https://www.sha.go.ke',
      contactInfo: 'SHA Helpline: 0800 720 601 | Email: info@sha.go.ke',
      requiredDocuments: [
        'National ID',
        'PWD Card',
        'SHA membership registration',
      ],
      howToApply:
          'Register with SHA at sha.go.ke or visit any SHA branch or Huduma Centre. Present your PWD Card when accessing public hospital services for enhanced benefits.',
    ),
  ];
}

// ── Matching Engine ───────────────────────────────────────────────────────────
class MatchingEngine {
  static MatchOutput match(AuthController auth) {
    final allResults = <MatchResult>[];

    for (final program in ProgramsDatabase.programs) {
      final result = _evaluateProgram(program, auth);
      if (result.matchScore > 0) allResults.add(result);
    }

    allResults.sort((a, b) {
      // Sort: fully eligible first, then by score
      if (a.fullyEligible && !b.fullyEligible) return -1;
      if (!a.fullyEligible && b.fullyEligible) return 1;
      return b.matchScore.compareTo(a.matchScore);
    });

    final fullyEligible = allResults.where((r) => r.fullyEligible).toList();
    final partials = allResults.where((r) => !r.fullyEligible && r.matchScore >= 10).toList();

    final MatchResult topMatch = fullyEligible.isNotEmpty
        ? fullyEligible.first
        : partials.isNotEmpty
            ? partials.first
            : allResults.first;

    final suggestions = allResults
        .where((r) => r.program.id != topMatch.program.id)
        .where((r) => r.matchScore >= 10)
        .take(2)
        .toList();

    return MatchOutput(topMatch: topMatch, suggestions: suggestions);
  }

  static MatchResult _evaluateProgram(AidProgram program, AuthController auth) {
    final reasons = <String>[];
    final missing = <String>[];
    final criticalMissing = <String>[];
    int score = 0;

    void addCriticalMissing(String message) {
      missing.add(message);
      criticalMissing.add(message);
    }

    switch (program.id) {
      case 'ncpwd_cash_transfer':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }
        score += 10;
        reasons.add('Kenyan citizenship confirmed');

        if (auth.disabilityStatus.value) {
          score += 30;
          reasons.add('You have a registered disability');
        } else {
          addCriticalMissing('Registered disability status required');
        }

        if (auth.pwdCardStatus.value) {
          score += 40;
          reasons.add('PWD card confirmed (mandatory for this program)');
        } else {
          addCriticalMissing('PWD card is mandatory — apply at NCPWD first');
        }

        if (auth.income.value < 10000) {
          score += 20;
          reasons.add('Your income qualifies for this support');
        } else {
          missing.add('Priority is given to applicants with income below KES 10,000');
        }
        break;

      case 'ncpwd_assistive_devices':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }
        score += 20;
        reasons.add('Kenyan citizenship confirmed');

        if (auth.disabilityStatus.value) {
          score += 25;
          reasons.add('Your disability status supports eligibility');
        } else {
          addCriticalMissing('Disability registration required');
        }

        if (auth.pwdCardStatus.value) {
          score += 15;
          reasons.add('PWD card available');
        } else {
          addCriticalMissing('PWD card required');
        }

        if (['Physical / Mobility', 'Visual Impairment', 'Hearing Impairment']
            .contains(auth.disabilityType.value)) {
          score += 40;
          reasons.add('${auth.disabilityType.value} is directly covered');
        } else {
          score += 10;
          reasons.add('Your disability type may qualify for certain devices');
          missing.add('A medical assessment report will confirm which device you qualify for');
        }
        break;

      case 'ncpwd_education':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }
        score += 10;
        reasons.add('Kenyan citizenship confirmed');

        if (auth.disabilityStatus.value || auth.pwdCardStatus.value) {
          score += 30;
          reasons.add('Disability status confirmed');
        } else {
          addCriticalMissing('Disability registration required');
        }

        if (auth.isStudent.value ||
            auth.employmentStatus.value == 'Student' ||
            auth.age.value <= 35) {
          score += 40;
          reasons.add('Age and student status qualify for education support');
        } else {
          addCriticalMissing('Priority given to current students aged 35 and below');
        }

        if (auth.income.value < 30000) {
          score += 20;
          reasons.add('Income level qualifies for bursary support');
        } else {
          missing.add('Lower income applicants are prioritised');
        }

        if (!auth.pwdCardStatus.value) {
          missing.add('PWD card recommended for a stronger application');
        }
        break;

      case 'nsnp_pwsd_ct':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }

        if ([
          'Physical / Mobility',
          'Intellectual / Cognitive',
          'Multiple Disabilities'
        ].contains(auth.disabilityType.value)) {
          score += 35;
          reasons.add('Your disability type is prioritised for this program');
        } else {
          addCriticalMissing('Program targets severe physical, cognitive, or multiple disabilities');
        }

        if (auth.income.value < 5000) {
          score += 30;
          reasons.add('Extreme low income qualifies for this cash transfer');
        } else if (auth.income.value < 10000) {
          score += 15;
          reasons.add('Low income may qualify — assessed by welfare committee');
          missing.add('Program targets extreme poverty (income ideally below KES 5,000)');
        } else {
          addCriticalMissing('Program targets extreme poverty (income below KES 5,000)');
        }

        if (auth.applicantType.value == 'Caretaker') {
          score += 25;
          reasons.add('Caretaker application matches this program\'s structure');
        } else {
          missing.add('Caretaker-led households are strongly prioritised');
        }

        if (auth.pwdCardStatus.value) {
          score += 10;
          reasons.add('PWD card confirmed');
        } else {
          addCriticalMissing('PWD card required');
        }
        break;

      case 'nfdk_tools':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }
        score += 10;
        reasons.add('Kenyan citizenship confirmed');

        if (auth.disabilityStatus.value || auth.pwdCardStatus.value) {
          score += 30;
          reasons.add('Disability status qualifies for NFDK support');
        } else {
          addCriticalMissing('Disability registration or PWD card required');
        }

        if (auth.pwdCardStatus.value) {
          score += 10;
          reasons.add('PWD card available');
        } else {
          addCriticalMissing('PWD card required for application');
        }

        if (auth.employmentStatus.value == 'Self-Employed' ||
            auth.employmentStatus.value == 'Unemployed') {
          score += 35;
          reasons.add('Employment status aligns with self-reliance goals');
        } else {
          missing.add('Priority given to unemployed or self-employed applicants');
        }

        if (auth.income.value < 20000) {
          score += 15;
          reasons.add('Income level qualifies for tools assistance');
        } else {
          missing.add('Lower income applicants are prioritised');
        }
        break;

      case 'ncpwd_employment':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }
        score += 10;
        reasons.add('Kenyan citizenship confirmed');

        if (auth.employmentStatus.value == 'Unemployed' ||
            auth.employmentStatus.value == 'Unable to Work') {
          score += 40;
          reasons.add('Unemployed status makes you a priority candidate');
        } else {
          missing.add('Priority given to unemployed or those unable to work');
        }

        if (auth.disabilityStatus.value || auth.pwdCardStatus.value) {
          score += 30;
          reasons.add('Registered disability status confirmed');
        } else {
          addCriticalMissing('Disability registration required');
        }

        if ([
          'Secondary',
          'Certificate / Diploma',
          'Undergraduate',
          'Postgraduate'
        ].contains(auth.educationLevel.value)) {
          score += 20;
          reasons.add('Education level supports vocational placement');
        } else {
          missing.add('Relevant education/training improves placement chances');
        }
        break;

      case 'ncpwd_legal':
        if (auth.disabilityStatus.value || auth.pwdCardStatus.value) {
          score += 60;
          reasons.add('Registered PWDs qualify for free legal services');
        } else {
          score += 25;
          reasons.add('Legal services may still be accessible — disability registration recommended');
          missing.add('Disability registration strengthens your access to legal services');
        }

        score += 25;
        reasons.add('Free service open to persons with disabilities');

        if (auth.citizenshipStatus.value == 'Kenyan Citizen') {
          score += 15;
          reasons.add('Kenyan citizenship confirmed');
        } else {
          missing.add('Some support may depend on local jurisdiction');
        }
        break;

      case 'county_bursary':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }

        if (auth.isStudent.value || auth.employmentStatus.value == 'Student') {
          score += 40;
          reasons.add('Student status qualifies for county bursary');
        } else {
          addCriticalMissing('Must be a current student to apply');
        }

        if (auth.disabilityStatus.value || auth.pwdCardStatus.value) {
          score += 30;
          reasons.add('Disability status qualifies for county support');
        } else {
          addCriticalMissing('Disability registration required');
        }

        if (auth.income.value < 30000) {
          score += 20;
          reasons.add('Income level qualifies for bursary');
        } else {
          missing.add('Lower income applicants are prioritised');
        }

        if (auth.location.value.isNotEmpty) {
          score += 10;
          reasons.add('Apply at ${auth.location.value} County offices');
        } else {
          missing.add('County of residence should be provided');
        }
        break;

      case 'nhif_disability':
        if (auth.citizenshipStatus.value != 'Kenyan Citizen') {
          addCriticalMissing('Must be a Kenyan citizen');
          break;
        }

        if (auth.disabilityStatus.value || auth.pwdCardStatus.value) {
          score += 50;
          reasons.add('PWD status qualifies for enhanced SHA benefits');
        } else {
          addCriticalMissing('PWD card or disability registration required');
        }

        if (auth.pwdCardStatus.value) {
          score += 25;
          reasons.add('PWD card supports SHA disability benefits');
        } else {
          missing.add('PWD card is strongly recommended');
        }

        score += 25;
        reasons.add('Healthcare coverage available to registered PWDs');
        break;
    }

    score = score.clamp(0, 100);

    // ── FIX: score caps ───────────────────────────────────────────────────────
    // If there are critical missing requirements → cap at 59 (clearly partial)
    if (criticalMissing.isNotEmpty) {
      score = score.clamp(0, 59);
    } else if (missing.isNotEmpty) {
      // Has non-critical missing items → cap at 89 (can never be 100%)
      score = score.clamp(0, 89);
    }
   
    final fullyEligible = criticalMissing.isEmpty && missing.isEmpty && score >= 60;

    return MatchResult(
      program: program,
      matchScore: score,
      matchReasons: reasons,
      missingRequirements: missing,
      fullyEligible: fullyEligible,
    );
  }
}