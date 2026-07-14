# Healthcare

Flutter + Firebase proof-of-concept for a mobile healthcare operations and analytics platform. It is designed for mobile healthcare units, outreach clinics, healthcare camps, and community health programs.

## Current Status

This POC is Firebase-backed and demo-ready for web and Android debug builds.

Implemented:

- Firebase Authentication with email/password users and Google sign-in.
- Cloud Firestore read/write integration using database ID `default`.
- Firestore rules deployment config for the named database.
- Role-aware navigation for administrator, coordinator, and Doctor/Nurse users.
- Dashboard, mobile units, visits, attendance, reports, referrals, inventory, alerts, and analytics screens.
- Demo data seeding for all main Firestore collections.
- Responsive desktop/tablet/mobile layouts.
- Android status-bar safe layout for app headers.

## Firebase Project

Project:

```text
Project name: healthcare
Project ID: healthcare-cf639
Project number: 1041371466897
Firestore database ID: default
```

Important: this Firebase project uses a named Firestore database called `default`, not the special `(default)` database. The app is configured for that in:

```text
lib/core/constants/firebase_constants.dart
firebase.json
```

If Firebase Console still shows **Start collection** / **Create collection**, check the database selector near the Firestore page title and select the database named `default`. Do not use `(default)` for this project; Firebase CLI confirmed `(default)` does not exist and would require billing to create.

## Demo Seed Data

The app does not load dummy records automatically. A clean Firestore database shows real empty states and zero metrics.

Use **Seed Demo Data** on the dashboard only when you intentionally want sample records for a demo. Use **Clear Demo Data** to remove the known seeded demo document IDs. The seed action writes demo documents to Firestore collections. The login screen also has explicit demo account buttons for quickly signing in as each role.

## Demo Accounts

Use these buttons on the login screen for quick demos. If the Firebase Auth account does not exist yet, the app creates that demo auth account and writes the matching `users/{uid}` role profile. It does not seed operational records unless **Seed Demo Data** is clicked.

| Role | Email | Password |
|---|---|---|
| Platform Administrator | `admin@healthcare.org` | `Admin@123` |
| Program Coordinator | `coordinator@healthcare.org` | `Coord@123` |
| Doctor/Nurse | `officer@healthcare.org` | `Officer@123` |

## Role Model

The visible app UI uses three roles:

| Role key in Firestore | Display role | Access |
|---|---|---|
| `admin` | Platform Administrator | Full navigation, dashboard, analytics, reports, units, inventory, alerts |
| `coordinator` | Program Coordinator | Operations monitoring, reports, referrals, inventory, alerts, analytics |
| `officer` | Doctor/Nurse | Field visits, attendance, service reports, referrals, inventory |

### Role Responsibilities And Limits

| Role | Main responsibility | Can access | Cannot / limited |
|---|---|---|---|
| Admin | Platform setup and overall control | Dashboard, mobile unit create/edit, field visits, attendance, reports, referrals, inventory, alerts, analytics, profile | Should not be used for routine field-only data entry except testing |
| Coordinator | Program monitoring and coordination | Dashboard, mobile units view, field visits, reports, referrals, inventory, alerts, analytics, profile | Cannot create/edit mobile units; no attendance module |
| Doctor/Nurse | Field operation entry | Dashboard, field visits, attendance check-in/out, service reports, referrals, inventory, profile | No mobile unit management, alerts center, or analytics hub |

The internal Firestore key for Doctor/Nurse is still `officer` so existing records and field names continue to work. The old `supervisor` role is not offered in the login or create-account UI.

### Why These Roles Are Different

- Admin sets up and controls the program. Admin creates mobile units, assigns Doctor/Nurse users to units, manages operational configuration, and can review all modules.
- Coordinator monitors the program. Coordinator looks at reports, referrals, inventory, alerts, analytics, and unit activity to coordinate operations, but does not create or edit mobile units.
- Doctor/Nurse records field work. Doctor/Nurse users start visits, mark attendance, submit service reports, create referrals, and update inventory usage from the field.

### Coordinator Workflow

Coordinator is an operations monitoring role, not a field-entry or setup role.

Typical coordinator workflow:

1. Open Dashboard to review program KPIs and today's operational status.
2. Open Mobile Units to see unit status, location, assigned Doctor/Nurse users, coverage, visits, and monthly activity.
3. Open Field Visits to inspect visit logs. Coordinators can open each visit detail to review unit, Doctor/Nurse, village, start/end time, GPS coordinates, patients served, photo evidence state, remarks, and status.
4. Open Service Reports to inspect submitted outreach reports. Coordinators can open report details to review population served, service counts, referral counts, remarks, submission time, and verification state.
5. Verify service reports after review.
6. Open Referrals to track patient referral status.
7. Open Inventory to monitor stock movement and low-stock risk.
8. Open Alerts to acknowledge operational issues.
9. Open Analytics to compare service trends, disease distribution, region performance, unit rankings, and coverage trends.

Coordinator cannot create/edit mobile units because that belongs to Admin setup. Coordinator also does not mark attendance or create field visit records because those actions belong to Doctor/Nurse users in the field.

New users are defined in the Firestore `users` collection. Important fields:

```text
name
email
role
designation
phone
unitId
district
state
avatarInitials
isActive
```

When a new Google user signs in and no profile exists yet, the app creates a default `officer` / Doctor/Nurse profile without demo unit, district, or state assignments. Edit that user's `users/{uid}` document in Firestore and change `role` to `admin`, `coordinator`, or `officer` as needed.

Role differences are visible mainly in navigation and allowed actions. The dashboard shows the same operational dataset, but users see different modules and actions based on their role.

## Mobile Unit Assignment Workflow

1. Sign in as an admin user.
2. Open Mobile Units.
3. Create or edit a mobile unit.
4. Choose the Doctor/Nurse from the **Assign Doctor/Nurse** dropdown. The dropdown shows name, user ID, and email.
5. Save the unit. The app stores the assigned user ID and also updates the selected Doctor/Nurse user's `users/{uid}.unitId`.
6. Sign in as that Doctor/Nurse user.
7. Start a field visit, submit a service report, or create a referral. The mobile unit/van can be selected by name from the form dropdown.

No one needs to manually type or remember mobile unit IDs or user IDs for normal demo use.

## Working Modules

### Authentication

- Email/password login through Firebase Authentication.
- Create account flow with role selection for administrator, coordinator, and Doctor/Nurse access.
- Google sign-in on web and Android.
- Existing Firebase Auth sessions are restored when the app reopens.
- Pressing **Continue with Google** signs out of the cached Google picker first so Android can show account choice again.
- User profile documents stored in `users`.
- Role-based navigation and module access.

### Executive Dashboard

- Reads operational summary from Firestore-backed data.
- Shows KPIs for units, active units, active today, villages, patients, referrals, and inventory alerts.
- Shows service trends, disease distribution, unit performance, and active alerts.
- Includes **Seed Demo Data** and **Clear Demo Data** buttons to explicitly manage demo collections.
- Refreshes after new service reports, referrals, visits, and inventory changes.

### Mobile Unit Monitoring

- Reads `mobile_units`.
- Admin users can create and edit mobile units from the Mobile Units screen.
- Admin users can assign a Doctor/Nurse from a name/email dropdown while creating or editing a unit. Saving the unit also writes that unit ID to the Doctor/Nurse profile.
- Unit setup captures status, district/state, GPS coordinates, team details, vehicle number, villages covered, visits, and monthly patient counts.
- Supports search and status filters.
- Shows unit list and unit profile details.
- Tracks status, team, location coordinates, patients served, visits, and last activity.

### Field Visit Verification

- Writes visit logs to `field_visits`.
- Doctor/Nurse users can start and end visits.
- Doctor/Nurse users choose the mobile unit/van by name from a dropdown before starting a visit.
- Captures simulated GPS coordinates and timestamps.
- Supports site photo evidence.
- Completed visits update unit activity metrics used by dashboard and analytics.
- If Firebase Storage is enabled, evidence is uploaded and the download URL is stored.
- If Storage is not enabled, the app stores a local evidence marker so the POC flow still works.

### Service Reporting

- Writes aggregated outreach reports to `service_reports`.
- Doctor/Nurse users choose the mobile unit/van by name from a dropdown before submitting a report.
- Captures population served and service counts.
- Coordinators/admin users can verify submitted reports.
- Verified state is persisted to Firestore.
- Submitted reports update dashboard/analytics totals and unit metrics.

### Referral Management

- Writes referrals to `referrals`.
- Doctor/Nurse users choose the mobile unit/van by name from a dropdown before creating a referral.
- Captures patient code, age, gender, reason, referred facility, priority, and notes.
- Supports status changes: pending, in progress, closed.
- Status changes are persisted to Firestore.
- Referral creation/status updates refresh dashboard and analytics counts.

### Attendance

- Writes records to `attendance`.
- Doctor/Nurse users can check in and check out.
- Captures simulated GPS coordinates.
- Captures a real selfie through the device camera for attendance verification.
- Selfie files are saved locally on the device/app storage only. They are not uploaded to Firebase Storage and are not written to Firestore.
- Shows attendance history.

### Inventory

- Reads and writes `inventory`.
- Add new stock items.
- Consume stock quantities.
- Tracks available, consumed, and remaining quantities.
- Generates low-stock alerts in `alerts` when stock crosses thresholds.
- Inventory changes refresh dashboard inventory-alert counts.

### Alert Center

- Reads and writes `alerts`.
- Displays unread and acknowledged alerts.
- Supports acknowledge one and mark all as read.
- Notification badge is shown in the app shell.

### Analytics

- Uses Firestore-backed reports, referrals, and unit data.
- Shows service trends, disease distribution, region performance, referral counts, unit rankings, and coverage trends.
- Shows empty or zero states when there is no current data.

## Firestore Collections

The app uses these collections:

```text
users
mobile_units
field_visits
attendance
service_reports
inventory
referrals
alerts
_metadata
```

`_metadata/seed` is updated when demo seed data is written.

## Firebase Setup Checklist

In Firebase Console:

- Authentication -> Sign-in method:
  - Enable Email/Password.
  - Enable Google.
- Authentication -> Settings -> Authorized domains:
  - Add `localhost`.
  - Add `127.0.0.1`.
- Cloud Firestore:
  - Database ID must be `default`.
  - Rules are managed by `firestore.rules`.
  - Current rules are open POC/demo rules so all modules can save data during the demo. Replace them with role-based rules before production.
- Android:
  - Debug SHA-1 and SHA-256 have been added to the Firebase Android app.
  - `android/app/google-services.json` has been regenerated.
- Storage:
  - Optional for this POC.
  - Enable Firebase Storage if you want actual photo upload URLs.

Deploy Firestore rules:

```powershell
cd D:\sandip\healthCare\healthcare
firebase.cmd deploy --only firestore:rules --project healthcare-cf639
```

## Run The App

Install dependencies:

```powershell
flutter pub get
```

Run on Chrome:

```powershell
flutter run -d chrome
```

Run on Android device:

```powershell
flutter run
```

Build web:

```powershell
flutter build web
```

Build Android debug APK:

```powershell
flutter build apk --debug
```

APK output:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Recommended Demo Flow

1. Create an account from the login screen and select the role you want to test.
2. Sign in as an admin user.
3. Open Mobile Units and create the real mobile units for your program.
4. Assign a Doctor/Nurse from the unit form's **Assign Doctor/Nurse** dropdown.
5. Review dashboard KPIs and charts populated from those units.
6. Open Dashboard and click **Seed Demo Data** only if you want sample records, or **Clear Demo Data** to remove seeded records.
7. Use the assigned Doctor/Nurse account to start a field visit, choose the mobile unit/van by name, attach evidence, then end the visit.
8. Submit a service report and choose the mobile unit/van by name.
9. Create a referral, choose the mobile unit/van by name, and change its status.
10. Check in/out under Attendance.
11. Use a Coordinator or Admin account and verify a service report.
12. Open Inventory, add an item, consume stock, and see low-stock alerts.
13. Open Alerts and acknowledge alerts.
14. Open Analytics and review scorecards/charts.

## Verification

The latest verified commands:

```powershell
flutter test
flutter build web
flutter build apk --debug
```

`flutter analyze` has no compile errors. Remaining messages, if any, are style/info lints.

## Notes And Limits

- GPS capture is simulated for the POC.
- Attendance selfie capture uses the device camera and stores the image locally only.
- Field visit photo evidence uses image selection and attempts Firebase Storage upload. If Storage is not enabled, the flow still completes with a local evidence marker.
- Google Maps is represented by unit coordinates/profile UI; a real map SDK integration can be added later.
- The project remains feature-first, but some Firebase access is intentionally centralized in `FirebaseDataService` to keep the POC simple and demo-friendly.
