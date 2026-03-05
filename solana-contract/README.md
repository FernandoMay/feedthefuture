# Feed the Future - Solana Smart Contract

## Overview

Feed the Future is a comprehensive Solana smart contract built with Anchor for managing food donations, pickups, deliveries, and user reputation in a decentralized food rescue platform.

## Features

### User Management
- Multi-role system (Donor, NGO, Volunteer, Community, Admin)
- User profiles with location tracking
- Reputation system with scoring
- User verification by admins

### Donation Lifecycle
- Create donations with detailed metadata
- Match donations with NGOs
- Schedule and complete pickups
- Schedule and complete deliveries
- Track donation status throughout the process

### Reputation & Rewards
- Dynamic reputation scoring
- Reward token creation for users
- Reputation-based access control

### Admin Functions
- Global configuration management
- User verification
- System-wide parameter control

## Architecture

The contract uses Program Derived Addresses (PDAs) for efficient data storage and retrieval:

- Users: `["user", user_pubkey]`
- Donations: `["donation", donor_pubkey, timestamp]`
- Pickup Requests: `["pickup", donation_pubkey]`
- Delivery Requests: `["delivery", donation_pubkey]`
- Global Config: `["config"]`
- Reward Tokens: `["reward", user_pubkey, token_name]`

## Installation & Setup

### Prerequisites
- Rust 1.70+
- Solana CLI 1.18+
- Anchor CLI 0.30+
- Node.js 18+

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Build the contract:
   ```bash
   anchor build
   ```

4. Run tests:
   ```bash
   anchor test
   ```

5. Deploy to localnet:
   ```bash
   anchor deploy
   ```

## Usage

### Initialize a User

```typescript
const location = {
  latitude: 19.4326,
  longitude: -99.1332,
  address: "Mexico City, Mexico",
  city: "Mexico City",
  state: "CDMX", 
  postalCode: "06000",
  country: "Mexico",
};

await program.methods
  .initializeUser(
    { donor: {} }, // UserRole
    "username",
    "email@example.com",
    location
  )
  .accounts({
    user: userPDA,
    authority: userKeypair.publicKey,
    systemProgram: SystemProgram.programId,
  })
  .signers([userKeypair])
  .rpc();
```

### Create a Donation

```typescript
const donationData = {
  name: "Fresh Vegetables",
  category: "Frutas y Verduras",
  quantity: 50,
  unit: "kg",
  description: "Mixed fresh vegetables",
  expirationDate: "2024-12-15",
  storageRequirements: "Keep refrigerated",
  isUrgent: true,
  isPerishable: true,
  requiresRefrigeration: true,
  images: ["https://example.com/image.jpg"],
};

await program.methods
  .createDonation(donationData)
  .accounts({
    donation: donationPDA,
    donorAccount: donorUserPDA,
    donor: donorKeypair.publicKey,
    systemProgram: SystemProgram.programId,
  })
  .signers([donorKeypair])
  .rpc();
```

## Contract Structure

### Accounts

- **UserAccount**: Stores user profile, role, reputation, and statistics
- **Donation**: Contains donation data, status, and logistics information
- **PickupRequest**: Manages pickup scheduling and completion
- **DeliveryRequest**: Manages delivery scheduling and completion
- **GlobalConfigAccount**: System-wide configuration parameters

### Events

The contract emits events for all major operations:
- UserCreated, UserProfileUpdated, UserVerified
- DonationCreated, DonationMatched
- PickupScheduled, PickupCompleted
- DeliveryScheduled, DeliveryCompleted
- ReputationUpdated, RewardTokenCreated
- ConfigInitialized, ConfigUpdated

### Errors

Comprehensive error handling with custom error types for:
- Authorization failures
- Invalid state transitions
- Parameter validation
- Rate limiting
- Account constraints

## Security Considerations

- Role-based access control
- PDA-based account ownership
- Input validation and sanitization
- Reputation-based permissions
- Timestamp-based operations

## Integration with Flutter

The contract is designed to integrate seamlessly with the Feed the Future Flutter app:

1. Use the `solana` and `anchor` packages in Flutter
2. Connect to the Solana network (devnet/mainnet)
3. Create wallet integrations for users
4. Implement transaction signing
5. Handle real-time event listening

## Development

### Running Tests

```bash
anchor test
```

### Local Development

```bash
solana-test-validator
anchor deploy
```

### Program ID

Update the `declare_id!` in `lib.rs` with your deployed program ID.

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For support and questions:
- GitHub Issues
- Discord community
- Documentation
