# 🌱 Feed the Future - Wallet Setup Guide for Devnet

## 📋 Tu Wallet Information
**Address**: `2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD`

## 🔧 Pasos para Configurar tu Wallet en Devnet

### 1. **Instalar Solana CLI (si no está instalado)**

```bash
# Usar installer oficial (recomendado)
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

# O usar cargo (si tienes Rust)
cargo install solana-cli
```

### 2. **Configurar tu Wallet**

#### Opción A: Importar desde Phantom/Solflare
```bash
# Si tienes tu private key en Phantom/Solflare:
# 1. Exporta tu private key desde la wallet
# 2. Guarda en un archivo (ej: ~/.config/solana/my-wallet.json)
# 3. Configura Solana CLI:
solana config set --keypair ~/.config/solana/my-wallet.json
```

#### Opción B: Crear nueva wallet y transferir SOL
```bash
# Crear nueva wallet
solana-keygen new --outfile ~/.config/solana/my-wallet.json

# Obtener la nueva dirección
solana address -k ~/.config/solana/my-wallet.json

# Transfiere SOL desde tu wallet actual (2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD)
# a la nueva dirección usando Phantom/Solflare
```

### 3. **Configurar para Devnet**
```bash
# Cambiar a Devnet
solana config set --url devnet

# Verificar configuración
solana config get
```

### 4. **Obtener SOL de Prueba**
```bash
# Solicitar airdrop (5 SOL)
solana airdrop 5

# Verificar balance
solana balance
```

### 5. **Verificar tu Wallet**
```bash
# Debería mostrar: 2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD
solana address

# Ver en Explorer
# https://explorer.solana.com/address/2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD?cluster=devnet
```

## 🚀 Deploy del Contrato

### 1. **Construir el Contrato**
```bash
cd /Users/fmf/Downloads/files (3)/solana-contract

# Construir con Anchor (si está disponible)
anchor build

# O construir manualmente
cd programs/feed-the-future
cargo build --release --target wasm32-unknown-unknown
```

### 2. **Desplegar en Devnet**
```bash
# Usar Anchor si está disponible
anchor deploy --provider.cluster devnet

# O desplegar manualmente
solana program deploy target/deploy/feed_the_future.so
```

### 3. **Actualizar Program ID**
Después del deploy, actualiza el Program ID en:
- `Anchor.toml`
- `lib.rs` (declare_id!)
- Tu app Flutter

## 📱 Integración con Flutter

### 1. **Actualizar Constants en Flutter**
```dart
// lib/core/constants/solana_constants.dart
class SolanaConstants {
  static const String network = 'devnet';
  static const String rpcUrl = 'https://api.devnet.solana.com';
  static const String programId = 'TU_PROGRAM_ID_AQUI'; // Actualizar después del deploy
  static const String userWallet = '2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD';
}
```

### 2. **Ejemplo de Conexión**
```dart
import 'package:solana/solana.dart';

class SolanaService {
  late final RpcClient rpcClient;
  late final String programId;
  
  void initialize() {
    rpcClient = RpcClient(SolanaConstants.rpcUrl);
    programId = SolanaConstants.programId;
  }
  
  Future<void> testConnection() async {
    try {
      final balance = await rpcClient.getBalance(SolanaConstants.userWallet);
      print('Wallet balance: ${balance.value} lamports');
    } catch (e) {
      print('Connection error: $e');
    }
  }
}
```

## 🔗 URLs Importantes

### Solana Explorer
- **Tu Wallet**: https://explorer.solana.com/address/2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD?cluster=devnet
- **Program Explorer**: https://explorer.solana.com/programs?cluster=devnet
- **Transaction Explorer**: https://explorer.solana.com/tx/SIGNATURE?cluster=devnet

### Faucets (para obtener SOL de prueba)
- **Official**: https://faucet.solana.com/
- **QuickNode**: https://faucet.quicknode.com/solana/devnet
- **Solana Beach**: https://solbeach.dev/faucet

### RPC Endpoints
- **Primary**: https://api.devnet.solana.com
- **Alchemy**: https://solana-devnet.g.alchemy.com/v2/YOUR_API_KEY
- **QuickNode**: https://solana-devnet.g.quicknode.com/YOUR_ENDPOINT

## 🧪 Testing en Devnet

### 1. **Crear Test Users**
```bash
# Crear wallets de prueba
solana-keygen new --outfile ~/.config/solana/test-donor.json
solana-keygen new --outfile ~/.config/solana/test-ngo.json
solana-keygen new --outfile ~/.config/solana/test-volunteer.json

# Obtener SOL para cada wallet
solana config set --keypair ~/.config/solana/test-donor.json
solana airdrop 2

solana config set --keypair ~/.config/solana/test-ngo.json
solana airdrop 2

solana config set --keypair ~/.config/solana/test-volunteer.json
solana airdrop 2
```

### 2. **Test desde Flutter**
```dart
// Test básico de conexión
Future<void> testDevnetConnection() async {
  final solana = SolanaService();
  solana.initialize();
  
  await solana.testConnection();
  
  // Probar crear usuario
  await solana.initializeUser(
    username: 'flutter_test',
    email: 'test@feedthefuture.org',
    location: Location(
      latitude: 19.4326,
      longitude: -99.1332,
      address: "Mexico City",
      city: "Mexico City",
      state: "CDMX",
      postalCode: "06000",
      country: "Mexico",
    ),
  );
}
```

## 📊 Monitoreo

### 1. **Dashboard de Actividad**
```dart
class DevnetMonitor {
  Future<void> monitorProgramActivity() async {
    final rpcClient = RpcClient('https://api.devnet.solana.com');
    
    // Obtener transacciones recientes del programa
    final signatures = await rpcClient.getSignaturesForAddress(
      programId,
      limit: 10,
    );
    
    for (final sig in signatures.value) {
      final tx = await rpcClient.getTransaction(sig.signature);
      print('Transaction: ${sig.signature}');
      print('Status: ${tx?.meta?.err == null ? "Success" : "Failed"}');
    }
  }
}
```

### 2. **Eventos en Tiempo Real**
```dart
void listenToProgramEvents() {
  final wsClient = WebSocketClient('wss://api.devnet.solana.com');
  
  wsClient.accountSubscribe(programId).listen((account) {
    // Procesar eventos del contrato
    final events = parseProgramEvents(account);
    updateUIWithEvents(events);
  });
}
```

## 🆘 Troubleshooting

### Problemas Comunes

1. **"No default signer found"**
   ```bash
   # Configurar tu wallet
   solana config set --keypair ~/.config/solana/my-wallet.json
   ```

2. **"Insufficient balance"**
   ```bash
   # Solicitar más SOL
   solana airdrop 5
   ```

3. **"Network timeout"**
   ```bash
   # Cambiar RPC endpoint
   solana config set --url https://api.devnet.solana.com
   ```

4. **"Program not found"**
   - Verifica que el Program ID sea correcto
   - Revisa que el contrato esté deployado
   - Usa el Explorer para verificar

### Debug Commands
```bash
# Ver configuración actual
solana config get

# Ver balance
solana balance

# Ver información de programa
solana program show <PROGRAM_ID>

# Ver logs del programa
solana logs <PROGRAM_ID>

# Ver cuenta específica
solana account <ACCOUNT_ADDRESS>
```

## ✅ Checklist Final

- [ ] Solana CLI instalado
- [ ] Wallet configurada (2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD)
- [ ] Conectado a Devnet
- [ ] SOL suficiente para pruebas (>2 SOL)
- [ ] Contrato construido y deployado
- [ ] Program ID actualizado en Flutter
- [ ] Tests básicos funcionando
- [ ] Explorer muestra transacciones

---

**🎉 Una vez completados estos pasos, tu contrato Feed the Future estará funcionando en Devnet con tu wallet!**

**Tu Wallet**: `2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD`  
**Explorer**: https://explorer.solana.com/address/2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD?cluster=devnet
