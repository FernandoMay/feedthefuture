# Feed the Future — Deployment

## Program ID

| Campo | Valor |
|---|---|
| Program ID (`declare_id!`) | `B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p` |
| Keypair del programa | `~/.config/solana/ftf_program.json` (copia de trabajo: `target/deploy/feed_the_future-keypair.json`) |
| Cluster objetivo | `devnet` (`Anchor.toml → [provider] cluster = "devnet"`) |
| Wallet fee-payer (Anchor) | `HHK352gcEYtYD23siG1D6jQfmk8oRuSw93nPW2F5MUGZ` (`~/.config/solana/id.json`) |
| Estado | ✅ **Desplegado en Devnet** (2026-11-24) |

El mismo ID está escrito en: `programs/feed-the-future/src/lib.rs` (`declare_id!`),
`Anchor.toml` (`[programs.localnet]` y `[programs.devnet]`), `flutter_config.dart`
(`FeedTheFutureConfig.programId`) y `scripts/run-tests.sh`.

> Nota: `Hz1i48mekLsLfEwv1a9SjjV9uDCh5UpDtrSKnLzPh5PM` NO existe en este
> repositorio. El único ID real es el de arriba.

## Verificación local (✅ hecha)

- `anchor build` → `target/deploy/feed_the_future.so` + `target/idl/feed_the_future.json` (IDL con `volunteer_account` writable en `complete_delivery`).
- `./scripts/run-tests.sh` → **30 passing / 0 failing** contra un validador local que carga el programa en `B4Cx…`.

## Deploy a Devnet (✅ hecho — 2026-11-24)

```bash
cd solana-contract
export PATH="$HOME/tools/solana-release/bin:$PATH"

# 1) La fee-payer debe tener ≥ 3 SOL en devnet (2.7 de rent + fees):
solana balance HHK352gcEYtYD23siG1D6jQfmk8oRuSw93nPW2F5MUGZ --url devnet

# 2) Desplegar (Anchor usa el keypair target/deploy/feed_the_future-keypair.json = B4Cx…):
anchor deploy --provider.cluster devnet

# 3) Verificar que lo desplegado coincide con el .so local:
solana program show B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p --url devnet
shasum -a 256 target/deploy/feed_the_future.so
solana program dump B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p /tmp/ftf_devnet.so --url devnet
shasum -a 256 /tmp/ftf_devnet.so        # debe coincidir con el local
```

Explorer: https://explorer.solana.com/address/B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p?cluster=devnet

### Evidencia del deploy (2026-11-24)

| Campo | Valor |
|---|---|
| Slot del deploy | `525924025` |
| Owner | `BPFLoaderUpgradeab1e11111111111111111111111` |
| ProgramData | `4fGnbJhuujztPyKTXb3FKWDhxtdTupu5Lm8bLVxAoC55` |
| Upgrade authority | `HHK352gcEYtYD23siG1D6jQfmk8oRuSw93nPW2F5MUGZ` |
| Tamaño | 385 856 bytes |
| Rent en la cuenta del programa | 1.96102732 SOL |
| **SHA-256 local** | `9ca7caee12c1d56bec2e02597cfdfad02e409fcb360fde0a453c876bbea2deb2` |
| **SHA-256 dump remoto** | `9ca7caee12c1d56bec2e02597cfdfad02e409fcb360fde0a453c876bbea2deb2` ✅ idéntico |
| IDL on-chain | inicializado (`idl` metadata: `BPZAhfamBzsBMdP8WJghLN1U7nuSBMb252cQU3XSJqhD`) |
| Balance fee-payer tras deploy | 8.012487102 SOL |

### Cómo conseguir SOL en devnet

- **faucet.solana.com** — máximo 2 solicitudes cada 8 horas (funciona tras esperar el cupo; acredita al instante).
- **Transferencia propia**: `2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD` (wallet de pruebas, ~10 SOL en devnet) → enviar ~3 SOL a la fee-payer.
- RPC `requestAirdrop` de devnet está **cerrado** (error 410); los faucets que lo usan (SOLFaucet) también fallan.

## Después del deploy

1. ✅ Tabla actualizada con fecha (2026-11-24) y slot (525924025).
2. ✅ Evidencia: `solana program show`, hashes SHA-256 coincidentes (`9ca7caee…2deb2`) y link de Explorer.
3. Tests contra devnet (opcional): la suite está diseñada para localnet
   (usa el keypair del faucet del validador local y `requestAirdrop`).
   Contra devnet exige fondear manualmente las 4 wallets de test y
   `RPC_URL=https://api.devnet.solana.com npm test`.
