# Feed the Future - Solana Smart Contract

## Program ID (Devnet)

| | |
|---|---|
| **Program ID / Dirección en Devnet** | `B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p` |
| Cluster | `devnet` |
| Keypair | `~/.config/solana/ftf_program.json` (copia: `target/deploy/feed_the_future-keypair.json`) |
| Fee-payer (Anchor) | `HHK352gcEYtYD23siG1D6jQfmk8oRuSw93nPW2F5MUGZ` (`~/.config/solana/id.json`) |
| Estado | ⏳ Pendiente de fondos — ver [`DEPLOYMENT.md`](DEPLOYMENT.md) |

La dirección en Devnet **es la que está dentro del `declare_id!`** en
`programs/feed-the-future/src/lib.rs`. El mismo ID está sincronizado en
`Anchor.toml` (`[programs.localnet]` y `[programs.devnet]`),
`flutter_config.dart` (`FeedTheFutureConfig.programId`) y
`scripts/run-tests.sh`.

> ⚠️ `Hz1i48mekLsLfEwv1a9SjjV9uDCh5UpDtrSKnLzPh5PM` **no** existe en este
> repositorio. El único ID real es el de arriba.

Explorer:
https://explorer.solana.com/address/B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p?cluster=devnet

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

4. Run tests (starts a local validator loaded with the program, then runs the suite):
   ```bash
   ./scripts/run-tests.sh
   ```
   Latest result: **30 passing / 0 failing** (log: `out/test_mocha.log`).

5. Deploy to Devnet (fee-payer needs ≥ 3 SOL, see [`DEPLOYMENT.md`](DEPLOYMENT.md)):
   ```bash
   anchor deploy --provider.cluster devnet
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
./scripts/run-tests.sh    # 30 passing / 0 failing
```

### Local Development

```bash
./scripts/start-validator.sh   # or: solana-test-validator
anchor deploy --provider.cluster localnet
```

### Program ID

`B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p` — el que está dentro del
`declare_id!` en `lib.rs` y el que se usa como dirección en Devnet. Si
regeneras el keypair con `anchor keys list`, ambos (keypair y `declare_id!`)
deben coincidir; no cambies solo uno.

### Deployment

Pasos de deploy y verificación en Devnet (incluyendo cómo conseguir SOL):
ver [`DEPLOYMENT.md`](DEPLOYMENT.md).

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
