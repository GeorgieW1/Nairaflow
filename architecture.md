# NairaPay Architecture Plan

## App Overview
NairaPay is a Nigerian digital payment platform that enables users to buy airtime, data, pay utility bills, manage wallet funds, and view transaction history with a sleek fintech UI.

## Technical Stack
- **Framework**: Flutter 3+ with Dart
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Networking**: Dio for API calls
- **Authentication**: JWT + Firebase Auth (optional)
- **Storage**: flutter_secure_storage for tokens, shared_preferences for app data
- **Architecture**: Clean Architecture with provider pattern

## UI/UX Design Approach
- **Style**: Sophisticated Monochrome (fintech-focused)
- **Primary Color**: #40376E (deep purple)
- **Typography**: Inter font family
- **Layout**: Card-based design, generous spacing, flat design
- **Navigation**: Bottom navigation for main sections

## Folder Structure
```
lib/
├── models/          # Data models
├── services/        # API and storage services
├── providers/       # Riverpod providers for state management
├── screens/         # UI screens
├── widgets/         # Reusable UI components
├── utils/           # Helper functions and constants
└── main.dart
```

## Key Features Implementation

### 1. Authentication Flow
- Login/Register screens with email/password
- Optional Firebase Google Auth
- JWT token management
- Secure token storage

### 2. Dashboard
- Wallet balance display
- Quick action buttons (Airtime, Data, Electricity, History)
- Recent transactions list
- User greeting

### 3. Payment Services
- Airtime purchase (MTN, Airtel, Glo, 9mobile)
- Data bundle purchase
- Electricity bill payment
- Network and amount selection

### 4. Wallet Management
- Fund wallet functionality
- Balance display
- Transaction history

### 5. Profile Management
- User information display
- Logout functionality

## Data Models
- User: id, name, email, phone, wallet_balance
- Transaction: id, type, amount, network, phone, status, created_at
- WalletFunding: id, amount, payment_method, status, created_at

## Services
- AuthService: Authentication, JWT management
- WalletService: Balance, funding operations
- PaymentService: Airtime, data, electricity purchases
- TransactionService: History management
- StorageService: Local data persistence

## API Integration
- Base URL: (TBD after deployment)
- JWT in Authorization header
- Error handling for 401 (token expiry)
- Network error handling
- Mock responses for development

## Implementation Priority
1. Setup dependencies and project structure
2. Create models and services
3. Implement authentication flow
4. Build dashboard with navigation
5. Implement payment screens
6. Add wallet and transaction features
7. Polish UI and add animations
8. Testing and error handling