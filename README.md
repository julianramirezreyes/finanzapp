# FinanzApp v2 🚀

**FinanzApp v2** is a comprehensive personal and household finance management application designed to give you total control over your money. Built with a modern tech stack, it seamlessly blends personal budgeting with advanced shared household financial management.

## 🌟 Key Features

### 🏡 Household Finance (Finanzas del Hogar)

manage shared expenses with your partner or roommates with transparency and fairness.

- **Shared History**: View combined income and expenses in a unified monthly timeline.
- **Smart Splitting**: Automatically split expenses (50/50, proportional to income, or custom).
- **Settlement Engine**: "Close the month" with a simple toggle to see who owes whom.
- **Ghost Transactions**: Add experimental or tracking-only transactions with the "No Affect Balance" toggle.

### 👤 Personal Finance

- **Waterfall Budgeting**: A unique budgeting flow: _Income -> Fixed Costs -> Savings -> Investments -> Guilt-Free Spending_.
- **Net Worth Tracking**: Monitor your assets (Vehicles, Real Estate) alongside your bank accounts.
- **Tax Watch**: Automatic tracking of UVT and tax thresholds (DIAN Colombia context).
- **Recurring Payments**: Automate your fixed expenses.

### 🔐 Security & Privacy

- **Account Vault (Bóveda)**: Securely store and view sensitive card details and account numbers, protected by biometric auth interaction patterns.
- **Privacy Mode**: Hide sensitive balances with a single tap.

## 🛠 Tech Stack

### Frontend (Mobile & Web)

- **Framework**: [Flutter](https://flutter.dev/) (SDK 3.10+)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)

### Backend (API)

- **Language**: [Go (Golang)](https://go.dev/)
- **Router**: Chi
- **Database**: PostgreSQL
- **Infrastructure**:
  - **Backend**: Hosted on [Render](https://render.com/) (with Keep-Alive workflows).
  - **Frontend**: Deployed on [Vercel](https://vercel.com/).
  - **CI/CD**: GitHub Actions.

## 📂 Project Structure

The project follows a **Clean Architecture** approach, ensuring scalability and maintainability.

```
lib/
├── features/           # Modular feature-based structure
│   ├── auth/           # Authentication logic
│   ├── dashboard/      # Main homescreen
│   ├── transactions/   # Transaction management
│   ├── household/      # Shared finance logic
│   ├── budgeting/      # Personal budgeting
│   └── ...
├── shared/             # Reusable widgets and utilities
├── core/               # App-wide configurations (Theme, Dio, Router)
└── main.dart           # Entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK installed.
- Access to the running Go Backend (local or remote).

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/finanzapp-v2.git
   cd finanzapp-v2
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the app:**

   ```bash
   # For Mobile
   flutter run

   # For Web
   flutter run -d chrome
   ```

## 🤝 Contributing

Contributions are welcome! Please create a Pull Request with a clear description of your changes.

---

_Built with ❤️ by [Your Name/Devian] for the Advanced Agentic Coding Project._
