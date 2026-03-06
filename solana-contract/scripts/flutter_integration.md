# Flutter Integration Guide for Devnet

## 📱 Configuración en Flutter

### 1. Actualizar Constants en Flutter

En `lib/core/constants/app_constants.dart`:

```dart
class SolanaConstants {
  // Devnet Configuration
  static const String rpcUrl = 'https://api.devnet.solana.com';
  static const String wsUrl = 'wss://api.devnet.solana.com';
  static const String programId = 'F1T3F11111111111111111111111111111111111111'; // Update after deploy
  
  // Environment
  static const String environment = 'devnet';
  static const String cluster = 'devnet';
}
```

### 2. Configuración de Wallet

```dart
// lib/services/solana_service.dart
class SolanaService {
  late final RpcClient rpcClient;
  late final WebSocketClient wsClient;
  
  void initialize() {
    rpcClient = RpcClient(SolanaConstants.rpcUrl);
    wsClient = WebSocketClient(SolanaConstants.wsUrl);
  }
}
```

### 3. Ejemplo de Integración

```dart
// Crear usuario en Devnet
Future<void> createUserOnDevnet() async {
  final program = await _loadProgram();
  
  final location = Location(
    latitude: 19.4326,
    longitude: -99.1332,
    address: "Mexico City, Mexico",
    city: "Mexico City",
    state: "CDMX",
    postalCode: "06000",
    country: "Mexico",
  );

  await program.methods
    .initializeUser(
      { donor: {} }, // UserRole
      "flutter_user",
      "user@feedthefuture.org",
      location,
    )
    .accounts({
      'user': await _findUserPDA(userPublicKey),
      'authority': userPublicKey,
      'systemProgram': SystemProgram.programId,
    })
    .signers([userKeypair])
    .rpc();
}
```

## 🔗 URLs Importantes de Devnet

### Solana Explorer
- **General**: https://explorer.solana.com/?cluster=devnet
- **Programas**: https://explorer.solana.com/programs?cluster=devnet
- **Tokens**: https://explorer.solana.com/tokens?cluster=devnet

### RPC Endpoints
- **Primary**: https://api.devnet.solana.com
- **Backup**: https://solana-devnet.g.alchemy.com/v2/YOUR_API_KEY

### Faucets para Test SOL
- **Official**: https://faucet.solana.com/
- **Solana Beach**: https://solbeach.dev/faucet
- **QuickNode**: https://faucet.quicknode.com/solana/devnet

## 🧪 Testing en Devnet

### 1. Preparar Cuentas de Test
```bash
# Crear nuevos keypairs para testing
solana-keygen new --outfile ~/.config/solana/test-donor.json
solana-keygen new --outfile ~/.config/solana/test-ngo.json
solana-keygen new --outfile ~/.config/solana/test-volunteer.json

# Obtener SOL de prueba
solana config set --keypair ~/.config/solana/test-donor.json
solana airdrop 5
```

### 2. Test Cases para Flutter
```dart
// Test de creación de usuario
test('Create user on devnet', () async {
  final result = await solanaService.createUser(
    role: UserRole.donor,
    username: 'test_donor',
    email: 'test@example.com',
    location: testLocation,
  );
  expect(result.success, true);
});

// Test de creación de donación
test('Create donation on devnet', () async {
  final donationData = DonationData(
    name: 'Test Food',
    category: 'Frutas y Verduras',
    quantity: 10,
    unit: 'kg',
    // ... otros campos
  );
  
  final result = await solanaService.createDonation(donationData);
  expect(result.success, true);
});
```

## 📊 Monitoreo en Devnet

### 1. Dashboard de Actividad
```dart
class DevnetMonitor {
  Future<void> monitorTransactions() async {
    final signatures = await rpcClient.getSignaturesForAddress(
      programId,
      limit: 10,
    );
    
    for (final sig in signatures.value) {
      final tx = await rpcClient.getTransaction(sig.signature);
      _processTransaction(tx);
    }
  }
}
```

### 2. Eventos en Tiempo Real
```dart
void listenToEvents() {
  wsClient.accountSubscribe(programId).listen((account) => {
    // Propiar eventos del contrato
    final events = parseEvents(account);
    _updateUI(events);
  });
}
```

## 🔄 Actualización de Program ID

Después de desplegar, actualiza el Program ID:

1. **En Anchor.toml**:
   ```toml
   [programs.devnet]
   feed_the_future = "ACTUAL_PROGRAM_ID"
   ```

2. **En lib.rs**:
   ```rust
   declare_id!("ACTUAL_PROGRAM_ID");
   ```

3. **En Flutter**:
   ```dart
   static const String programId = 'ACTUAL_PROGRAM_ID';
   ```

## 🚀 Deploy Process

### 1. Pre-deploy Checklist
- [ ] Test SOL sufficient (>2 SOL)
- [ ] Program builds successfully
- [ ] All tests pass locally
- [ ] Backup of current keys
- [ ] Documentation updated

### 2. Deploy Commands
```bash
# 1. Switch to devnet
solana config set --url devnet

# 2. Check balance
solana balance

# 3. Deploy
anchor deploy --provider.cluster devnet

# 4. Verify
solana program show <PROGRAM_ID>
```

### 3. Post-deploy Verification
- [ ] Program appears in Solana Explorer
- [ ] Can call initialize_user
- [ ] Events are emitted correctly
- [ ] Flutter app can connect
- [ ] All functions work as expected

## 🆘 Troubleshooting

### Common Issues
1. **Insufficient SOL**: Request more from faucet
2. **Network timeouts**: Check RPC endpoint
3. **Program ID mismatch**: Update all references
4. **Transaction failures**: Check error logs in Explorer

### Debug Tools
- **Solana Explorer**: https://explorer.solana.com/?cluster=devnet
- **Logs**: `solana logs <PROGRAM_ID>`
- **Account info**: `solana account <ACCOUNT>`
