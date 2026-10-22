# AidLink

**A smart matching system that helps Persons with Disabilities (PWDs) and their caregivers in Kenya find government support programmes they may qualify for.**

Final-year project, BSc Computer Science, University of Nairobi.

## The problem

Disability support in Kenya is spread across several agencies (NCPWD, NSNP, NFDK, SHA, county governments), each with its own eligibility rules and paperwork. AidLink brings those rules into one place. A user fills in one profile and gets a ranked list of programmes, with plain explanations of what they meet and what is missing.

## Features

- **Rule-based matching engine** covering 9 national and county programmes, with transparent reasons for every result
- **Ranked results:** Strong, Good, Partial or Low match, with a 0-100 score and a list of missing requirements
- **4-step profile wizard** (applicant type, disability, personal and financial details), including a Caretaker mode for dependants
- **Secure accounts:** bcrypt password hashing, JWT sessions, email verification and password reset
- **PWD card upload** with an admin review flow (pending, verified or rejected)
- **Admin dashboard:** user management, PWD card verification, usage statistics
- **Accessibility:** large tap targets, screen reader labels, light/dark/system themes, and a voice assistant that reads results aloud

## How matching works

The engine (`lib/services/matching_engine.dart`) runs on the device using IF-THEN rules. Each programme adds points for every condition the user meets. Critical gates (such as citizenship or a PWD card) cap the score at 59; other missing items cap it at 89. A programme is only labelled Strong or Good when nothing is missing. Because the rules are deterministic, the same profile always gives the same result, and every result can be explained.

| Programme | Provider |
|-----------|----------|
| Cash Transfer | NCPWD |
| Assistive Devices | NCPWD |
| Education Bursary | NCPWD |
| Employment Support | NCPWD |
| Legal Advisory Services | NCPWD |
| Persons with Severe Disabilities Cash Transfer | NSNP, Ministry of Labour |
| Tools of Trade | NFDK |
| County Bursary | County governments |
| Enhanced Healthcare Benefits | Social Health Authority |

## Tech stack

| Layer | Technology |
|-------|------------|
| App | Flutter (Dart), GetX for state management, flutter_tts |
| Backend | Node.js, Express.js, Joi validation, Multer, Nodemailer |
| Database | MongoDB with Mongoose |
| Security | JWT, bcrypt, role-based admin middleware |

## Project structure

```
aidlink/
├── Backend/          REST API (models, routes, middleware, startup, cron)
│   ├── seed.js         loads programme data into MongoDB
│   └── .env.example    settings template
├── lib/              Flutter app source (screens, controllers, services)
├── android/ ios/ web/
└── pubspec.yaml      Flutter dependencies
```

## Getting started

**Requirements:** Flutter SDK, Node.js, and a MongoDB database (local or Atlas).

**1. Backend**
```bash
cd Backend
npm install
cp .env.example .env     # then fill in your own values
node index.js            # runs on http://localhost:5000
```

**2. Flutter app** (from the repository root)
```bash
flutter pub get
flutter run -d chrome
```
Make sure the API address in the app points at your running backend.

**3. Admin account**
Admin accounts are created on the server with `node setAdmin.js`, not through the sign-up form.

## Configuration

Copy `Backend/.env.example` to `Backend/.env`. The file is ignored by Git and must never be committed.

```
MONGO_URI=your_mongodb_connection_string
JWT_PRIVATE_KEY=a_long_random_secret
PORT=5000
# plus the email settings used for verification and reset emails
```

## Testing

Tested manually across functional, security, usability, accessibility, API and performance checks. The matching engine runs in about 1.4 seconds for all nine programmes, and all 13 functional test cases passed. There are no automated tests yet.

## Known limitations and next steps

- Runs on localhost only; cloud deployment is planned.
- Programme rules are hardcoded in the matching engine, so changing a rule means editing the code. A database-driven rule editor is the next step.
- English only. Kiswahili support is planned.
- Keyboard navigation is only partly WCAG 2.1 compliant.
- PWD cards are checked by hand. There is no integration with NCPWD systems.
- Before deployment: restrict CORS to the app's own address, serve uploaded ID images only to their owner and admins, and rely only on the `isAdmin` flag for admin access.

## Author

**Nancy Luka**, Computer Science student, University of Nairobi
[LinkedIn](https://linkedin.com/in/nancy-luka) · [GitHub](https://github.com/nancyluka200)
