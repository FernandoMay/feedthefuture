# Feed the Future — Deployment

## Program ID

| Campo | Valor |
|---|---|
| Program ID (`declare_id!`) | `B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p` |
| Keypair del programa | `~/.config/solana/ftf_program.json` (copia de trabajo: `target/deploy/feed_the_future-keypair.json`) |
| Cluster objetivo | `devnet` (`Anchor.toml → [provider] cluster = "devnet"`) |
| Wallet fee-payer (Anchor) | `HHK352gcEYtYD23siG1D6jQfmk8oRuSw93nPW2F5MUGZ` (`~/.config/solana/id.json`) |
| Estado | ⏳ **Pendiente de fondos** — la fee-payer necesita ≥ 3 SOL en devnet |

El mismo ID está escrito en: `programs/feed-the-future/src/lib.rs` (`declare_id!`),
`Anchor.toml` (`[programs.localnet]` y `[programs.devnet]`), `flutter_config.dart`
(`FeedTheFutureConfig.programId`) y `scripts/run-tests.sh`.

> Nota: `Hz1i48mekLsLfEwv1a9SjjV9uDCh5UpDtrSKnLzPh5PM` NO existe en este
> repositorio. El único ID real es el de arriba.

## Verificación local (✅ hecha)

- `anchor build` → `target/deploy/feed_the_future.so` + `target/idl/feed_the_future.json` (IDL con `volunteer_account` writable en `complete_delivery`).
- `./scripts/run-tests.sh` → **30 passing / 0 failing** contra un validador local que carga el programa en `B4Cx…`.

## Deploy a Devnet (⏳ pendiente)

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

### Cómo conseguir SOL en devnet

- **faucet.solana.com** — máximo 2 solicitudes cada 8 horas (cupó agotado al escribir esto).
- **Transferencia propia**: `2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD` (wallet de pruebas, ~10 SOL en devnet) → enviar ~3 SOL a la fee-payer.
- RPC `requestAirdrop` de devnet está **cerrado** (error 410); los faucets que lo usan (SOLFaucet) también fallan.

## Después del deploy

1. Actualizar esta tabla con fecha, firma y slot del deploy.
2. Adjuntar al evidence pack: `solana program show`, hashes SHA-256 coincidentes y links de Explorer.
3. Tests contra devnet (opcional): la suite está diseñada para localnet
   (usa el keypair del faucet del validador local y `requestAirdrop`).
   Contra devnet exige fondear manualmente las4 wallets de test y
   `RPC_URL=https://api.devnet.solana.com npm test`.
