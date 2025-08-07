# CryptoSafe - Digital Asset Custody Protocol

A secure, decentralized custody solution for STX tokens built on the Stacks blockchain. CryptoSafe enables users to time-lock their assets with advanced trustee management for enhanced security and inheritance planning.

##  Overview

CryptoSafe provides a robust digital asset custody system that allows users to:
- Lock STX tokens for predetermined periods
- Designate trusted parties as emergency trustees
- Implement inheritance and succession planning
- Protect assets from unauthorized access
- Maintain full control over custody terms
##  Key Features

## Custody Accounts
- **Time-locked Security**: Assets remain locked until maturity date
- **Flexible Terms**: Custody periods from 1 day to 1 year
- **Account Extensions**: Extend custody terms as needed
- **Multi-asset Support**: Built for STX with expandability for other tokens

###  Trustee System
- **Emergency Access**: Designated trustees can claim dormant accounts
- **Activity Tracking**: Automatic monitoring of account activity
- **Grace Periods**: Configurable windows for trustee intervention
- **Status Management**: Active/inactive trustee controls

###  Security Features
- **Smart Contract Custody**: Assets secured by blockchain logic
- **Activity Monitoring**: Last access timestamps prevent unauthorized claims
- **Multi-condition Verification**: Multiple checks before fund releases
- **Audit Trail**: Complete transaction history on-chain

##  Contract Functions

### Account Management
```clarity
;; Create a new custody account
(open-custody-account custody-term trustee trustee-window)

;; Extend existing custody term
(extend-custody-term additional-blocks)

;; Update account activity
(update-access)
```

### Asset Operations
```clarity
;; Deposit STX into custody
(secure-deposit amount)

;; Withdraw matured funds
(withdraw-funds amount)

;; Emergency trustee withdrawal
(trustee-withdrawal account-owner)
```

### Trustee Management
```clarity
;; Update trustee designation
(update-trustee new-trustee)

;; Check trustee withdrawal eligibility
(can-trustee-withdraw account-owner trustee)
```

### Read-Only Functions
```clarity
;; Get account details
(get-account-details account-owner)

;; Check if funds are mature
(is-mature account-owner)

;; Get remaining custody time
(get-remaining-custody-time account-owner)
```

##  Getting Started

### Prerequisites
- Stacks CLI or Clarinet for development
- STX tokens for transactions
- Basic understanding of Clarity smart contracts

### Deployment
1. Clone the repository:
```bash
git clone <repository-url>
cd cryptosafe
```

2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

3. Interact with the contract using Stacks CLI or web interface

### Usage Examples

#### Opening a Custody Account
```clarity
;; Create 30-day custody with trustee
(contract-call? .cryptosafe open-custody-account 
    u4320  ;; 30 days in blocks
    (some 'SP1ABC...)  ;; trustee address
    u4320  ;; trustee window
)
```

#### Depositing Assets
```clarity
;; Deposit 1000 microSTX
(contract-call? .cryptosafe secure-deposit u1000000)
```

#### Withdrawing After Maturity
```clarity
;; Withdraw 500 microSTX after maturity
(contract-call? .cryptosafe withdraw-funds u500000)
```

##  Constants & Configuration

| Constant | Value | Description |
|----------|--------|-------------|
| `MIN-CUSTODY-TERM` | 144 blocks | Minimum custody period (≈1 day) |
| `MAX-CUSTODY-TERM` | 52,560 blocks | Maximum custody period (≈1 year) |
| `MIN-TRUSTEE-WINDOW` | 144 blocks | Minimum trustee intervention window |
| `DEFAULT-TRUSTEE-WINDOW` | 4,320 blocks | Default trustee window (≈30 days) |

##  Architecture

### Data Structures
```clarity
custody-accounts: {
    account-owner: principal,
    secured-balance: uint,
    maturity-height: uint,
    custody-term: uint,
    trustee: (optional principal),
    trustee-status: uint,
    trustee-window: uint,
    last-access: uint,
    currency-type: string-ascii
}
```

### Error Codes
| Code | Description |
|------|-------------|
| u100 | ERR-ACCESS-DENIED |
| u101 | ERR-ACCOUNT-NOT-FOUND |
| u102 | ERR-ACCOUNT-EXISTS |
| u103 | ERR-FUNDS-NOT-MATURE |
| u104 | ERR-TRUSTEE-WINDOW-EXPIRED |
| u105 | ERR-INSUFFICIENT-FUNDS |
| u106 | ERR-INVALID-TERM |
| u107 | ERR-EXTENSION-TOO-SHORT |
| u108 | ERR-INVALID-TRUSTEE |
| u109 | ERR-NO-TRUSTEE-SET |
| u110 | ERR-TRUSTEE-NOT-ACTIVE |

##  Use Cases

### 1. Long-term Savings
Lock tokens for extended periods to prevent impulsive spending and encourage disciplined saving habits.

### 2. Inheritance Planning
Designate family members or legal representatives as trustees to ensure asset transfer in case of incapacitation.

### 3. Business Escrow
Secure business funds with time-locked releases and multi-party oversight for contract fulfillment.

### 4. Investment Vesting
Implement vesting schedules for team tokens or investment returns with trustee oversight.

### 5. Emergency Funds
Create time-locked emergency reserves with trusted party access for crisis situations.

##  Testing

Run the test suite using Clarinet:
```bash
clarinet test
```

Key test scenarios:
- Account creation and validation
- Deposit and withdrawal operations
- Trustee functionality
- Time-lock enforcement
- Error handling

##  Security Considerations

### Best Practices
- **Trustee Selection**: Choose reliable, accessible trustees
- **Activity Management**: Regularly update account activity
- **Term Planning**: Consider custody terms carefully
- **Private Key Security**: Protect account access credentials

### Known Limitations
- Single STX token support (expandable)
- Fixed block-time assumptions
- Trustee trust model dependency
- On-chain activity requirements

##  Contributing

We welcome contributions! Please see our contributing guidelines:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### Development Setup
```bash
npm install
clarinet check
clarinet test
```

##  License

This project is licensed under the MIT License - see the LICENSE file for details.

##  Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Stacks Explorer](https://explorer.stacks.co/)

##  Support

For questions, issues, or suggestions:
- Create an issue on GitHub
- Join our community Discord
- Review the documentation

##  Roadmap

### Phase 1 (Current)
-  Core custody functionality
-  Trustee management
-  STX token support

### Phase 2 (Planned)
-  Multi-token support (SIP-010)
-  Advanced trustee features
-  Web interface development

### Phase 3 (Future)
-  Mobile application
-  Integration APIs
-  Advanced analytics

