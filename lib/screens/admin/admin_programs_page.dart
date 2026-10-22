import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminProgramsPage extends StatefulWidget {
  const AdminProgramsPage({super.key});

  @override
  State<AdminProgramsPage> createState() => _AdminProgramsPageState();
}

class _AdminProgramsPageState extends State<AdminProgramsPage> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> categories = [
    'All', 'Cash Transfer', 'Assistive Devices',
    'Education', 'Healthcare', 'Employment', 'Legal',
  ];

  final List<Map<String, dynamic>> programs = [
    {
      'id': 'ncpwd_cash_transfer',
      'name': 'NCPWD Cash Transfer Program',
      'organization': 'National Council for Persons with Disabilities (NCPWD)',
      'category': 'Cash Transfer',
      'description': 'Monthly cash transfers to vulnerable persons with disabilities to support basic needs. Targets households with severe disability in extreme poverty.',
      'website': 'https://ncpwd.go.ke',
      'hasOnlineApplication': true,
      'onlineLink': 'https://ncpwd.ecitizen.go.ke',
      'physicalLocations': [
        'NCPWD Headquarters — Opposite ABC Place, Waiyaki Way, Nairobi',
        'Any NCPWD County Office (all 47 counties)',
        'Huduma Centre in your county',
      ],
      'requiredDocuments': [
        'Completed NCPWD application form (download from ncpwd.go.ke or eCitizen)',
        'Copy of National ID card (for adults 18+) OR Birth Certificate (for minors)',
        'Disability Medical Assessment Report from a government-gazetted hospital, signed by a qualified medical professional',
        'Valid PWD Card / Disability Registration Certificate from NCPWD (mandatory)',
        'One recent passport-sized photograph (colour)',
        'Bank account details or M-Pesa number for cash disbursement',
        'Proof of residence (e.g. utility bill or letter from local chief)',
      ],
      'howToApply': 'Visit the nearest NCPWD County Office or apply via eCitizen (ecitizen.go.ke). Download and complete the NCPWD application form. Attach all required documents and submit at the office.',
      'contact': 'Tel: +254 20 3554248 | Email: info@ncpwd.go.ke',
      'deadline': 'Applications accepted throughout the year',
      'note': 'You must first register with NCPWD and obtain a Disability Registration Certificate before applying.',
    },
    {
      'id': 'ncpwd_assistive_devices',
      'name': 'NCPWD Assistive Devices Program (NDFPWD)',
      'organization': 'National Development Fund for Persons with Disabilities (NDFPWD) / NCPWD',
      'category': 'Assistive Devices',
      'description': 'Provision of wheelchairs, hearing aids, white canes, prosthetics, callipers, surgical boots, and other assistive devices. Priority given to those needing devices for learning, training, or work.',
      'website': 'https://ncpwd.go.ke/application-forms/',
      'hasOnlineApplication': true,
      'onlineLink': 'https://ncpwd.go.ke/ndfpwd-application-forms/',
      'physicalLocations': [
        'NCPWD Headquarters — Opposite ABC Place, Waiyaki Way, Nairobi',
        'Any NCPWD County Office (all 47 counties)',
        'APDK (Association for the Physically Disabled of Kenya) — for wheelchair applications',
      ],
      'requiredDocuments': [
        'Completed NDFPWD application form (download from ncpwd.go.ke/application-forms)',
        'Copy of National ID card OR Birth Certificate (for minors)',
        'Disability Medical Assessment Report from a government-gazetted hospital',
        'For visual disability: Ophthalmology report signed by a consultant ophthalmologist from a government hospital',
        'For hearing disability: Audiology report and BERA signed by a consultant ENT from a government hospital',
        'For mental/psychiatric disability: Psychiatric report signed by a consultant psychiatrist',
        'PWD Card / Disability Registration Certificate (strongly recommended)',
        'One recent passport-sized photograph',
        'Medical assessment report recommending the specific device required',
      ],
      'howToApply': 'Download the NDFPWD application form from ncpwd.go.ke/application-forms. Complete with a medical assessment report specifying the device needed. Submit at NCPWD Headquarters or any County Office.',
      'contact': 'Tel: +254 20 3554248 | Email: info@ncpwd.go.ke | APDK: +254 20 3877490',
      'deadline': 'Applications accepted throughout the year',
      'note': 'Expensive items such as motorcars and laptops are not covered.',
    },
    {
      'id': 'ncpwd_education',
      'name': 'NCPWD Education Bursaries & Scholarships',
      'organization': 'National Development Fund for Persons with Disabilities (NDFPWD) / NCPWD',
      'category': 'Education',
      'description': 'Bursaries and scholarships for learners with disabilities at secondary, tertiary, and university levels.',
      'website': 'https://ncpwd.go.ke/application-forms/',
      'hasOnlineApplication': true,
      'onlineLink': 'https://ncpwd.go.ke/ndfpwd-application-forms/',
      'physicalLocations': [
        'NCPWD Headquarters — Opposite ABC Place, Waiyaki Way, Nairobi',
        'Any NCPWD County Office (all 47 counties)',
        'Sub-County Education Office in your area',
      ],
      'requiredDocuments': [
        'Completed NDFPWD bursary application form (from ncpwd.go.ke or NCPWD office)',
        'Copy of National ID card OR Birth Certificate (for minors)',
        'PWD Card / Disability Registration Certificate from NCPWD',
        'Disability Medical Assessment Report from a government-gazetted hospital',
        'Admission or enrollment letter from educational institution',
        'Most recent academic results / report card',
        'Fee structure from the institution',
        'Recommendation letter from head teacher or disability liaison officer',
        'One recent passport-sized photograph',
      ],
      'howToApply': 'Download the bursary application form from ncpwd.go.ke or collect from any NCPWD office. Submit the completed form with all documents during the open application period.',
      'contact': 'Tel: +254 20 3554248 | Email: info@ncpwd.go.ke',
      'deadline': 'Applications open annually — check ncpwd.go.ke for current dates',
      'note': 'Top-up education funding is also available through the Ministry of Education — contact your school\'s Board of Management.',
    },
    {
      'id': 'nsnp_pwsd_ct',
      'name': 'Persons with Severe Disabilities Cash Transfer (PWSD-CT)',
      'organization': 'National Safety Net Programme (NSNP) — Ministry of Labour & Social Protection',
      'category': 'Cash Transfer',
      'description': 'KES 2,000 per household per month (paid every two months) for households with a member who has a severe disability requiring full-time caregiver support.',
      'website': 'https://www.labour.go.ke',
      'hasOnlineApplication': false,
      'onlineLink': '',
      'physicalLocations': [
        'Sub-County Social Development Officer\'s office (your nearest Sub-County headquarters)',
        'Local Chief\'s office or Ward Administrator\'s office',
        'Ministry of Labour & Social Protection — Social Protection offices in each county',
        'Kenya Commercial Bank (KCB) or Equity Bank branch (for payment collection after enrolment)',
      ],
      'requiredDocuments': [
        'National ID card of the Person with Disability',
        'National ID card of the Caregiver / Guardian',
        'PWD Card / Disability Registration Certificate from NCPWD',
        'Disability Medical Assessment Report confirming severe disability requiring full-time care',
        'Proof of residence (letter from area Chief or local administration)',
        'Proof of non-enrolment in any other government cash transfer programme (declaration letter)',
        'Poverty assessment confirmation by the local welfare committee',
        'One recent passport-sized photograph of both PWD and caregiver',
      ],
      'howToApply': 'This programme has NO online application. Visit your Sub-County Social Development Officer or local Chief\'s office to register. A local welfare committee will assess household eligibility.',
      'contact': 'Ministry of Labour & Social Protection: +254 20 2729800 | Contact your Sub-County Social Development Officer',
      'deadline': 'Enrolment is ongoing — subject to programme capacity',
      'note': 'Household must NOT be enrolled in any other government cash transfer programme. Priority is given to extreme poverty households.',
    },
    {
      'id': 'nfdk_tools',
      'name': 'NFDK Tools of Trade & Assistive Devices',
      'organization': 'National Fund for the Disabled of Kenya (NFDK)',
      'category': 'Assistive Devices',
      'description': 'Income-generating tools (sewing machines, welding kits, barber/salon kits, carpentry tools, farming kits, etc.) and mobility aids to promote economic self-reliance for PWDs.',
      'website': 'https://nfdk.or.ke',
      'hasOnlineApplication': true,
      'onlineLink': 'https://nfdk.or.ke',
      'physicalLocations': [
        'NFDK Offices — 2nd Floor, Rehema House, Kaunda/Standard Street, Nairobi (8am–5pm weekdays)',
        'Deputy County Commissioner\'s office in your county (drop completed forms here)',
        'County Commissioner\'s office (application forms available here)',
      ],
      'requiredDocuments': [
        'Completed NFDK Individual Assistance Form (Form B) — download from nfdk.or.ke or collect from Deputy County Commissioner\'s office',
        'Copy of National ID card (attach to form as specified)',
        'PWD Card / Disability Registration Certificate from NCPWD',
        'Recommendation letter from the Area Assistant-Chief (filled in Form B, Section B)',
        'Endorsement from the Department of Social Protection Officer at Sub-County level',
        'Proof of vocational training, trade test certificate, or explanation of how skill was acquired',
        'One recent passport-sized photograph',
      ],
      'howToApply': 'Download NFDK Form B from nfdk.or.ke or collect from your County Commissioner\'s office. Obtain endorsements from your Area Assistant-Chief and Sub-County Social Protection Officer. Drop the completed form at your nearest Deputy County Commissioner\'s office.',
      'contact': 'NFDK Offices: +254 20 2215390 | Rehema House, Kaunda/Standard Street, Nairobi | Email: info@nfdk.or.ke',
      'deadline': 'Applications accepted throughout the year; tools distributed annually',
      'note': 'Applicants should have a vocational skill for which they want the tools.',
    },
    {
      'id': 'ncpwd_employment',
      'name': 'NCPWD Employment & Vocational Training',
      'organization': 'National Council for Persons with Disabilities (NCPWD)',
      'category': 'Employment',
      'description': 'Job placement portal, vocational training support, and employer matching for persons with disabilities.',
      'website': 'https://ncpwd.go.ke',
      'hasOnlineApplication': true,
      'onlineLink': 'https://placement.ncpwd.go.ke/public/',
      'physicalLocations': [
        'NCPWD Headquarters — Opposite ABC Place, Waiyaki Way, Nairobi',
        'Any NCPWD County Office (all 47 counties)',
        'Huduma Centre (for document verification and registration support)',
      ],
      'requiredDocuments': [
        'Copy of National ID card',
        'PWD Card / Disability Registration Certificate from NCPWD',
        'Disability Medical Assessment Report from a government-gazetted hospital',
        'Copies of academic or professional certificates',
        'Curriculum Vitae (CV) / Resume',
        'Recent passport-sized photograph',
        'Trade test or vocational training certificate (if applicable)',
      ],
      'howToApply': 'Register on the NCPWD Job Placement Portal at placement.ncpwd.go.ke/public/ to access job opportunities. Alternatively, visit any NCPWD County Office in person.',
      'contact': 'Tel: +254 20 3554248 | Email: info@ncpwd.go.ke | Job Portal: placement.ncpwd.go.ke/public/',
      'deadline': 'Applications accepted throughout the year',
      'note': 'NCPWD is mandated to ensure 5% of employment positions in public and private sectors are filled by PWDs.',
    },
    {
      'id': 'ncpwd_legal',
      'name': 'NCPWD Legal Advisory Services',
      'organization': 'National Council for Persons with Disabilities (NCPWD) — Legal Services Department',
      'category': 'Legal',
      'description': 'Free walk-in legal advisory services for persons with disabilities on disability rights, discrimination, employment disputes, and access to justice.',
      'website': 'https://ncpwd.go.ke',
      'hasOnlineApplication': false,
      'onlineLink': '',
      'physicalLocations': [
        'NCPWD Headquarters — Legal Services Department, Opposite ABC Place, Waiyaki Way, Nairobi (walk-in, no appointment needed)',
        'Any NCPWD County Office — for referral to legal services',
      ],
      'requiredDocuments': [
        'Copy of National ID card',
        'Brief written description of the legal issue you need assistance with',
        'PWD Card / Disability Registration Certificate (recommended, not mandatory)',
        'Any relevant supporting documents related to your case (e.g. employment letter, court documents)',
      ],
      'howToApply': 'WALK-IN service. Visit the NCPWD Legal Services Department at NCPWD Headquarters on any working day. No appointment required. Services are completely FREE OF CHARGE.',
      'contact': 'Tel: +254 20 3554248 | Email: info@ncpwd.go.ke',
      'deadline': 'Walk-in service available Monday–Friday, 8am–5pm',
      'note': 'Grounded in the Constitution 2010, Disability Act No.14 of 2003, and the UN CRPD.',
    },
    {
      'id': 'county_bursary',
      'name': 'County Government Disability Bursary',
      'organization': 'County Government (varies by county) — County Social Services',
      'category': 'Education',
      'description': 'Education bursaries offered by individual county governments for students with disabilities. Requirements and amounts vary by county.',
      'website': 'https://www.cra.go.ke',
      'hasOnlineApplication': false,
      'onlineLink': '',
      'physicalLocations': [
        'Sub-County Education Office in your county (primary application point)',
        'County Social Services Department — County Headquarters',
        'Ward Administrator\'s office (for ward-level bursaries)',
        'Your school\'s Board of Management',
      ],
      'requiredDocuments': [
        'Copy of National ID card OR Birth Certificate (for minors)',
        'PWD Card / Disability Registration Certificate from NCPWD (if available)',
        'Disability Medical Assessment Report from a government-gazetted hospital',
        'Current school admission or enrollment letter',
        'Fee structure from the educational institution',
        'Proof of residence in the county (letter from Chief, utility bill, or rental agreement)',
        'Most recent academic results or report card',
        'One recent passport-sized photograph',
      ],
      'howToApply': 'Visit your Sub-County Education Office or County Social Services Department. Requirements and application periods vary by county.',
      'contact': 'Contact your County Social Services Department | cra.go.ke',
      'deadline': 'Varies by county — check your county government website',
      'note': 'Nairobi, Mombasa, Kisumu, and Nakuru counties have dedicated disability bursary funds.',
    },
    {
      'id': 'nhif_disability',
      'name': 'SHA/NHIF Enhanced Benefits for PWDs',
      'organization': 'Social Health Authority (SHA) — formerly NHIF',
      'category': 'Healthcare',
      'description': 'Enhanced healthcare coverage and exemptions for persons with disabilities in public hospitals, including chronic illness management and rehabilitation services.',
      'website': 'https://www.sha.go.ke',
      'hasOnlineApplication': true,
      'onlineLink': 'https://www.sha.go.ke',
      'physicalLocations': [
        'Any SHA (formerly NHIF) branch office countrywide',
        'Huduma Centre in your county',
        'Any public hospital — present PWD Card for free services',
      ],
      'requiredDocuments': [
        'Copy of National ID card',
        'PWD Card / Disability Registration Certificate from NCPWD (mandatory for enhanced benefits)',
        'SHA membership registration (register at sha.go.ke or any SHA branch)',
        'Disability Medical Assessment Report from a government-gazetted hospital',
        'One recent passport-sized photograph',
      ],
      'howToApply': 'Register with SHA online at sha.go.ke or visit any SHA branch or Huduma Centre. Present your PWD Card when accessing public hospital services.',
      'contact': 'SHA Helpline: 0800 720 601 (toll-free) | Email: info@sha.go.ke | sha.go.ke',
      'deadline': 'Registration open throughout the year',
      'note': 'NHIF has been replaced by SHA as of 2024. PWDs are entitled to free medical services in all public hospitals under the Persons with Disabilities Act No. 14 of 2003.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    return programs.where((p) {
      final matchCat = _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          p['name'].toString().toLowerCase().contains(q) ||
          p['organization'].toString().toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Cash Transfer': return Colors.green;
      case 'Assistive Devices': return Colors.blue;
      case 'Education': return Colors.purple;
      case 'Healthcare': return Colors.red;
      case 'Employment': return Colors.teal;
      case 'Legal': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Cash Transfer': return Icons.payments_outlined;
      case 'Assistive Devices': return Icons.accessible_outlined;
      case 'Education': return Icons.school_outlined;
      case 'Healthcare': return Icons.local_hospital_outlined;
      case 'Employment': return Icons.work_outline;
      case 'Legal': return Icons.gavel_outlined;
      default: return Icons.info_outline;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open link',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showProgramDetail(Map<String, dynamic> p) {
    final color = _categoryColor(p['category']);
    final docs = List<String>.from(p['requiredDocuments']);
    final locations = List<String>.from(p['physicalLocations']);
    final hasOnline = p['hasOnlineApplication'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // ── WHITE background ─────────────────────────────────────────────
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        maxChildSize: 0.97,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          // ── Force white background on inner container too ─────────────
          color: Colors.white,
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_categoryIcon(p['category']), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['name'],
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      Text(p['organization'],
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _badge(p['category'], color),
                        const SizedBox(width: 8),
                        _badge(
                          hasOnline ? 'Online Available' : 'Physical Only',
                          hasOnline ? Colors.green : Colors.orange,
                          icon: hasOnline ? Icons.wifi : Icons.location_on_outlined,
                        ),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),

                // Description
                _sectionHeader('About This Program', Icons.info_outline, Colors.black54),
                Text(p['description'],
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.5)),
                const SizedBox(height: 16),

                // Required Documents
                _sectionHeader('Required Documents', Icons.description_outlined, Colors.blue),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: docs.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(e.value,
                                style: const TextStyle(
                                    fontSize: 12, height: 1.4, color: Colors.black87))),
                      ]),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Physical locations
                _sectionHeader('Where to Apply Physically', Icons.location_on_outlined, Colors.orange),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: locations.map((loc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.place, size: 14, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(loc,
                            style: const TextStyle(
                                fontSize: 12, height: 1.4, color: Colors.black87))),
                      ]),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // How to apply
                _sectionHeader('How to Apply', Icons.assignment_turned_in_outlined, Colors.teal),
                Text(p['howToApply'],
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.5)),
                const SizedBox(height: 16),

                // Deadline
                _sectionHeader('Deadline / Timeline', Icons.calendar_today_outlined, Colors.red),
                Row(children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p['deadline'],
                      style: const TextStyle(fontSize: 13, color: Colors.red))),
                ]),
                const SizedBox(height: 16),

                // Note
                if ((p['note'] ?? '').isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p['note'],
                          style: const TextStyle(
                              fontSize: 12, height: 1.4, color: Colors.black87))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact
                _sectionHeader('Contact Information', Icons.phone_outlined, Colors.grey),
                Text(p['contact'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),

                // Buttons
                if (hasOnline && (p['onlineLink'] ?? '').isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: const Text('Apply Online / Visit Website'),
                      onPressed: () => _launchUrl(p['onlineLink']),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.language, size: 16),
                    label: const Text('Visit Official Website'),
                    onPressed: () => _launchUrl(p['website']),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.8)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.2), thickness: 1)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Programs (${programs.length})'),
        backgroundColor: const Color(0xff0A3080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search + Filter
          Container(
            color: const Color(0xff0A3080),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search programs...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? const Color(0xff0A3080)
                                        : Colors.white)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Program cards
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No programs match your search',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final color = _categoryColor(p['category']);
                      final hasOnline = p['hasOnlineApplication'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: color.withValues(alpha: 0.2)),
                        ),
                        child: InkWell(
                          onTap: () => _showProgramDetail(p),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(_categoryIcon(p['category']),
                                        color: color, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['name'],
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87)),
                                        Text(p['organization'],
                                            style: const TextStyle(
                                                fontSize: 11, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey, size: 18),
                                ]),
                                const SizedBox(height: 8),
                                Text(p['description'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  _badge(p['category'], color),
                                  const SizedBox(width: 8),
                                  _badge(
                                    hasOnline ? 'Online' : 'Physical Only',
                                    hasOnline ? Colors.green : Colors.orange,
                                    icon: hasOnline
                                        ? Icons.wifi
                                        : Icons.location_on_outlined,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${List.from(p['requiredDocuments']).length} docs',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}