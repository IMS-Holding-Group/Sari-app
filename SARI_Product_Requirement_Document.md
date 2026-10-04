# Product Requirement Document (PRD)

# SARI Mobile Application
## Smart Electrical Risk Detection & Prevention Platform

---

# 1. Product Overview

## Product Name
**SARI**

## Product Category
IoT + AI Powered Electrical Safety Monitoring Platform.

## Product Vision

SARI transforms electrical systems from reactive protection into proactive prevention.

Instead of waiting for:
- Short circuits
- Current leakage
- Overload
- Electrical failures

SARI continuously monitors electrical behavior and predicts risks before incidents happen.

---

# 2. Product Objectives

The application should allow users to:

## Monitor
Track electrical parameters in real-time:
- Current
- Voltage
- Leakage current
- Device status

## Detect
Identify abnormal electrical patterns:
- Overcurrent
- Leakage
- Voltage fluctuation
- Abnormal behavior

## Predict
Use AI models to detect possible future failures.

## Protect
Send alerts and trigger automatic safety actions.

---

# 3. Target Users

## Residential Users
Home owners who need:
- Electrical safety
- Fire prevention
- Remote monitoring

## B2B Users
- Factories
- Industrial facilities
- Real estate developers
- Construction companies

## Government Users
- Municipalities
- Regulatory entities
- Electricity-related organizations

---

# 4. System Architecture

```
Electrical Sensors
        |
        |
IoT Device / SARI Hardware
        |
        |
Cloud Database
        |
        |
AI Risk Analysis Engine
        |
        |
Mobile Application
        |
        |
Alerts & Reports
```

---

# 5. Technology Stack

## Mobile Application

Framework:
- Flutter

Reasons:
- Cross platform development
- Fast UI implementation
- Firebase compatibility
- Strong chart and dashboard ecosystem

---

## Backend

Platform:
- Firebase

Services:

### Firebase Authentication
Used for:
- User accounts
- Roles
- Permissions

### Firebase Firestore
Stores:
- Users
- Devices
- Measurements
- Alerts
- Reports

### Firebase Cloud Messaging
Used for:
- Push notifications
- Emergency warnings

### Firebase Storage
Stores:
- Reports
- Documents
- Images

---

# 6. User Roles

## Residential User

Can:
- View electrical status
- Receive alerts
- Monitor devices
- View reports

## Facility Manager

Can:
- Monitor multiple locations
- View heatmaps
- Manage devices
- Export reports

## Admin

Can:
- Manage users
- Manage sensors
- Analyze system performance

---

# 7. Application Navigation

Bottom Navigation:

```
Home
Monitoring
Alerts
Reports
Profile
```

---

# 8. Screen Specifications

# Screen 1: Login / Registration

## Purpose
Secure access to the platform.

## Components
- SARI Logo
- Email field
- Password field
- Login button
- Create account button

---

# Screen 2: Home Dashboard

## Purpose
Provide instant electrical safety overview.

## Header

Contains:
- User name
- Notification icon
- Profile

---

## Safety Score Card

Example:

```
Electrical Safety Score

92%

SAFE
```

---

## Main Indicators

### Current Status
Example:
Normal

### Voltage
Example:
220 V

### Leakage
Example:
0.02 A

### Connected Devices
Example:
12 Devices

---

# Screen 3: Live Monitoring

## Purpose
Real-time electrical data visualization.

## Data Display

- Current graph
- Voltage graph
- Leakage graph
- Device status

---

# Screen 4: AI Risk Detection

## Purpose
Display AI analysis results.

Example:

```
AI Analysis

No abnormal behavior detected

Risk Level:
LOW
```

---

Risk Alert Example:

```
Electrical Risk Detected

Cause:
Abnormal Current Pattern

Probability:
87%

Recommended Action:
Inspect circuit
```

---

# Screen 5: Alerts Center

## Purpose
Manage all safety warnings.

Alert Card:

```
High Current Detected

Location:
Main Panel

Time:
10:42 AM

Status:
Resolved
```

Severity:

- Critical
- Warning
- Information

---

# Screen 6: Heatmap

## Purpose
Visualize electrical risk locations.

Example:

```
Floor 1

Room A  🟢
Room B  🔴
Room C  🟡
```

For industrial users:

- Factory zones
- Machines
- Electrical panels

---

# Screen 7: Reports

## Daily Report

Includes:
- Electrical events
- Peak current
- Warnings

## Monthly Safety Report

Includes:
- Risk trends
- Avoided incidents
- Device performance

---

# Screen 8: Device Management

Users can manage:

- Sensors
- Locations
- Circuits

Example:

```
Device:
SARI Sensor 01

Location:
Main Panel

Status:
Online
```

---

# Screen 9: Emergency Control

For authorized users.

Feature:

Remote power shutdown.

Example:

```
CUT POWER
```

with confirmation.

---

# 9. Firebase Database Structure

## Users

```
users

userID
name
email
role
organizationID
```

---

## Devices

```
devices

deviceID
userID
location
status
installationDate
```

---

## Measurements

```
measurements

deviceID
timestamp
current
voltage
leakage
temperature
```

---

## Alerts

```
alerts

alertID
deviceID
type
severity
timestamp
status
```

---

## Reports

```
reports

reportID
organizationID
date
riskScore
events
```

---

# 10. AI Model Requirements

## Input Data

- Current
- Voltage
- Leakage
- Time
- Location
- Historical behavior

## Output

- Risk probability
- Risk type
- Severity level
- Recommended action

---

# 11. MVP Version

## Phase 1

Required features:

- Login
- Sensor connection
- Real-time dashboard
- Current monitoring
- Voltage monitoring
- Leakage detection
- Push notifications
- Basic reports

---

## Phase 2

Advanced features:

- AI prediction
- Heatmap
- Multiple locations
- Automatic shutdown
- Advanced analytics

---

# 12. UI Design Direction

## Style

Professional Safety Platform.

Keywords:

- Smart Monitoring
- Industrial IoT
- Data Dashboard
- Safety System

---

## Colors

Primary:
```
#0B1F3A
```

Blue:
```
#0066FF
```

Warning:
```
#FF9800
```

Danger:
```
#E53935
```

Safe:
```
#22C55E
```

---

# 13. Product Summary

SARI is an AI-powered electrical safety platform that connects smart sensors with a mobile application to continuously monitor electrical behavior, detect abnormal patterns, predict risks, and protect people and assets before electrical accidents occur.
