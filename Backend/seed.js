
require('dotenv').config();
const mongoose = require('mongoose');
const { Program } = require('./models/program');

const programs = [
  {
    name: 'NCPWD Cash Transfer Program',
    description: 'Monthly cash transfers to vulnerable persons with disabilities to support basic needs and improve livelihoods.',
    category: 'Disability',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment',
        'Intellectual / Cognitive', 'Mental Health', 'Multiple Disabilities', 'Other'
      ],
      maxIncome: 10000,
    },
    applicationLink: 'https://www.ncpwd.go.ke',
    documentsRequired: [
      'National ID or Birth Certificate',
      'PWD Card (mandatory)',
      'Proof of disability (medical certificate)',
      'Bank account details or M-Pesa number',
      'Recent passport photo',
    ],
    contactInfo: {
      phone: '020-3554248',
      email: 'info@ncpwd.go.ke',
      address: 'NCPWD Offices, Nairobi'
    },
    isActive: true,
  },
  {
    name: 'NCPWD Assistive Devices Program',
    description: 'Provision of wheelchairs, hearing aids, white canes, prosthetics, and other assistive devices to persons with disabilities.',
    category: 'Disability',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment'
      ],
    },
    applicationLink: 'https://www.ncpwd.go.ke',
    documentsRequired: [
      'National ID or Birth Certificate',
      'PWD Card',
      'Medical assessment report recommending the device',
      'Recent passport photo',
    ],
    contactInfo: {
      phone: '020-3554248',
      email: 'info@ncpwd.go.ke',
      address: 'NCPWD Offices, Nairobi'
    },
    isActive: true,
  },
  {
    name: 'NCPWD Education Bursary & Scholarships',
    description: 'Bursaries and scholarships for learners with disabilities at secondary, tertiary, and university levels.',
    category: 'Education',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment',
        'Intellectual / Cognitive', 'Multiple Disabilities', 'Other'
      ],
      maxAge: 35,
      maxIncome: 30000,
      studentOnly: true,
    },
    applicationLink: 'https://www.ncpwd.go.ke',
    documentsRequired: [
      'National ID or Birth Certificate',
      'PWD Card',
      'Admission letter from institution',
      'Most recent academic results',
      'Fee structure from institution',
      'Recommendation letter',
    ],
    contactInfo: {
      phone: '020-3554248',
      email: 'info@ncpwd.go.ke',
      address: 'NCPWD Offices, Nairobi'
    },
    isActive: true,
  },
  {
    name: 'Persons with Severe Disabilities Cash Transfer (PWSD-CT)',
    description: 'Regular cash transfers to households caring for persons with severe disabilities who require full-time assistance. Targets extreme poverty.',
    category: 'Disability',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Intellectual / Cognitive', 'Multiple Disabilities'
      ],
      maxIncome: 5000,
    },
    applicationLink: 'https://www.labour.go.ke',
    documentsRequired: [
      'National ID of PWD and caretaker',
      'PWD Card',
      'Proof of severe disability (medical certificate)',
      'Proof of residence',
      'Poverty assessment by local welfare committee',
      'Confirmation of non-enrollment in other cash transfer programs',
    ],
    contactInfo: {
      phone: '020-2729800',
      email: 'info@labour.go.ke',
      address: 'Ministry of Labour, Nairobi'
    },
    isActive: true,
  },
  {
    name: 'NFDK Tools of Trade & Assistive Devices',
    description: 'Provides tools of trade (sewing machines, welding equipment) and mobility aids to promote economic self-reliance for PWDs.',
    category: 'Disability',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment', 'Intellectual / Cognitive'
      ],
      maxIncome: 20000,
      employmentStatus: ['Unemployed', 'Self-Employed'],
    },
    applicationLink: 'https://www.nfdkenya.org',
    documentsRequired: [
      'National ID',
      'PWD Card',
      'Application letter stating need',
      'Recommendation from community leader or social worker',
      'Recent passport photo',
    ],
    contactInfo: {
      phone: '020-2215390',
      email: 'nfdk@nfdkenya.org',
      address: 'NFDK Offices, Nairobi'
    },
    isActive: true,
  },
  {
    name: 'NCPWD Employment & Vocational Training',
    description: 'Vocational training, job placement, and employment support services for persons with disabilities to promote economic inclusion.',
    category: 'Employment',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment',
        'Intellectual / Cognitive', 'Multiple Disabilities', 'Other'
      ],
      employmentStatus: ['Unemployed', 'Self-Employed'],
    },
    applicationLink: 'https://www.ncpwd.go.ke',
    documentsRequired: [
      'National ID',
      'PWD Card',
      'Academic or professional certificates',
      'CV / Resume',
    ],
    contactInfo: {
      phone: '020-3554248',
      email: 'info@ncpwd.go.ke',
      address: 'NCPWD Offices, Nairobi'
    },
    isActive: true,
  },
  {
    name: 'NCPWD Legal Advisory Services',
    description: 'Free legal advice and support on disability rights, discrimination cases, and access to justice for persons with disabilities.',
    category: 'Disability',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment',
        'Intellectual / Cognitive', 'Mental Health', 'Multiple Disabilities', 'Other'
      ],
    },
    applicationLink: 'https://www.ncpwd.go.ke',
    documentsRequired: [
      'National ID',
      'Brief written description of legal issue',
    ],
    contactInfo: {
      phone: '020-3554248',
      email: 'info@ncpwd.go.ke',
      address: 'NCPWD Offices, Nairobi'
    },
    isActive: true,
  },
  {
    name: 'County Government Disability Bursary',
    description: 'Education bursaries offered by individual county governments specifically targeting students with disabilities.',
    category: 'Education',
    provider: 'Government',
    eligibility: {
      studentOnly: true,
      maxIncome: 30000,
    },
    applicationLink: 'https://www.cra.go.ke',
    documentsRequired: [
      'National ID or Birth Certificate',
      'PWD Card (if available)',
      'Admission or enrollment letter',
      'Fee structure',
      'Proof of residence in the county',
    ],
    contactInfo: {
      phone: 'Contact your county offices',
      email: '',
      address: 'Sub-County Education Office'
    },
    isActive: true,
  },
  {
    name: 'NHIF Enhanced Benefits for PWDs',
    description: 'Enhanced healthcare coverage and exemptions for persons with disabilities including chronic illness management.',
    category: 'Healthcare',
    provider: 'Government',
    eligibility: {
      requiredDisabilities: [
        'Physical / Mobility', 'Visual Impairment', 'Hearing Impairment',
        'Intellectual / Cognitive', 'Mental Health', 'Multiple Disabilities', 'Other'
      ],
    },
    applicationLink: 'https://www.nhif.or.ke',
    documentsRequired: [
      'National ID',
      'PWD Card',
      'NHIF membership card or registration',
    ],
    contactInfo: {
      phone: '0800 720 601',
      email: 'info@nhif.or.ke',
      address: 'NHIF Branch near you'
    },
    isActive: true,
  },
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI || process.env.DB_URI);
    console.log('Connected to MongoDB...');
    await Program.deleteMany({});
    console.log('Cleared existing programs...');
    await Program.insertMany(programs);
    console.log(`Seeded ${programs.length} programs successfully!`);
    mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('Error seeding programs:', error);
    process.exit(1);
  }
}

seed();