# Feed the Future — Solana implementation roadmap

> **Goal:** turn the existing Anchor program into a tested, Devnet-deployed, privacy-conscious and genuinely usable part of the Flutter application. This is an execution checklist, not a claim that the integration is already complete.
>
> **Scope:** Solana Devnet first. Do not deploy to Mainnet or handle real funds until the security, privacy, operational and product gates below are explicitly signed off.

## 0. Repository baseline (verified before this roadmap)

The repository already contains a substantial Solana implementation. Do not replace it blindly.

- Anchor workspace: `solana-contract/`, Anchor version configured as `0.31.1`.
- Program source: `solana-contract/programs/feed-the-future/src/lib.rs` (about 29.6 KB).
- Existing instruction handlers: `initialize_user`, `update_user_profile`, `verify_user`, `create_donation`, `match_donation`, `schedule_pickup`, `complete_pickup`, `schedule_delivery`, `complete_delivery`, `update_reputation`, `create_reward_token`, `initialize_config`, `update_config`.
- Existing state accounts include user, donation, pickup request, delivery request and global configuration accounts; events are defined for the main lifecycle actions.
- Existing Flutter app is Firebase-backed. Its `pubspec.yaml` currently has no Solana client or wallet dependency.
- `solana-contract/flutter_config.dart` is a template: PDA methods return placeholder strings and service methods only print TODO messages. It is not wired into the Flutter app.
- `Anchor.toml`, `lib.rs` and the Flutter template currently contain the same obvious placeholder Program ID: `F1T3F11111111111111111111111111111111111111`. Treat it as **not a verified deployed Program ID** until a real build, keypair and Devnet lookup prove otherwise.
- `solana-contract/tests/feed_the_future.ts` currently has one initialization test and catches/logs errors rather than rethrowing; that can make a failing instruction look like a passing test.
- `solana-contract/tests/Cargo.toml` declares a Rust binary whose path is a TypeScript file. The test/build layout needs to be normalized.
- `solana-contract/target/` is present in the repository tree. Build outputs should be generated in CI/local builds, not committed as source.

**Baseline conclusion:** there is real Anchor source and a broad domain model, but the checked-in Flutter integration is a stub and the checked-in test does not yet provide trustworthy end-to-end proof. Devnet deployment and a real Program ID remain unverified.

---

## Product and architecture decisions

### What belongs on Solana

Use the program as the verifiable state-transition and audit layer for:
- wallet-linked participant identity and role (with minimal public profile data);
- donation creation and lifecycle state;
- NGO matching and volunteer pickup/delivery assignments;
- completion attestations and event history;
- optional reputation/reward accounting, only after its trust model is defined.

### What stays in Firebase / off-chain

Keep Firebase for authentication, email, push notifications, chat/community, AI classification, search, operational dashboards, image storage and private user data. Store only a content hash or opaque reference on-chain when an audit proof is needed.

**Never put email addresses, phone numbers, exact home addresses, private notes, access tokens, private image URLs or other personal data on a public ledger.** The current Rust account model includes email and location fields; review and migrate this before any real-user deployment. Use coarse/public location or an off-chain record hash instead.

### Wallet model

A wallet is the transaction signer and on-chain identity. Firebase authentication remains a separate application identity. Link them with an explicit signed-message challenge and persist the verified wallet mapping server-side; never trust a wallet address supplied by the client without signature verification. Do not ask users to paste seed phrases or private keys into the app.

---

## Execution plan

Priority definitions: **P0 = blocker / correctness or security**, **P1 = core feature**, **P2 = production-quality integration**, **P3 = optional expansion**.

### Phase 1 — Stabilize the existing program (P0)

- [ ] **FTF-SOL-001 — Freeze and inventory the contract surface.** Document every instruction, account, PDA seed, signer, writable account, emitted event, error and role permission. Map each handler to the product workflow.
  - Acceptance: a checked-in instruction/account matrix exists; every mutating instruction has an identified authority and state-transition rule.
- [ ] **FTF-SOL-002 — Establish a real Program ID.** Generate/identify the program keypair securely, derive the public key, and make `declare_id!`, `Anchor.toml`, generated IDL/client configuration agree. Do not commit private key material.
  - Acceptance: no placeholder ID remains; CI checks that all public ID references match; the keypair is stored outside Git in a controlled secret location.
- [ ] **FTF-SOL-003 — Repair the build/test toolchain.** Standardize Anchor 0.31.1, Solana/Agave CLI and Rust/SBF toolchain versions; fix the TypeScript-vs-Rust test layout; add the required JS package manifest/lockfile and deterministic install commands; replace obsolete build commands where necessary.
  - Acceptance: clean checkout can install, build the SBF program, generate IDL and run tests with documented commands; no reliance on tracked `target/` artifacts.
- [ ] **FTF-SOL-004 — Make tests fail honestly.** Remove swallowed exceptions; assert expected state, emitted events, errors and transaction signatures. Add deterministic local validator/LiteSVM tests.
  - Acceptance: deliberately breaking an instruction makes CI fail; all current handlers have at least one positive and one unauthorized/invalid-input test.
- [ ] **FTF-SOL-005 — Security review of account constraints.** Verify admin-only operations, NGO matching authority, volunteer assignment, donor ownership, PDA seeds/bump checks, signer requirements, account mutability, replay/idempotency, timestamp handling, arithmetic and all state transitions.
  - Acceptance: a threat-model checklist and tests cover privilege escalation, forged accounts, duplicate completion, cross-donation account substitution, invalid roles and unauthorized reputation/config changes.
- [ ] **FTF-SOL-006 — Fix donation address uniqueness.** Current donation PDA uses donor + on-chain timestamp. Review same-slot collisions and choose a collision-safe nonce/counter or client-generated unique seed with explicit validation.
  - Acceptance: two donations from the same wallet can be created safely without address collision; tests cover repeated/rapid submissions.
- [ ] **FTF-SOL-007 — Privacy/data minimization.** Remove email and precise/private location from public account data. Define which location fields are intentionally public; use hashes/opaque IDs for private Firebase records and photo evidence.
  - Acceptance: a written on-chain data schema and privacy review approve every persisted field before Devnet pilot.
- [ ] **FTF-SOL-008 — Define token/reward semantics.** `create_reward_token` currently emits an event; it does not by itself create/mint an SPL token. Decide whether rewards are on-chain points in the program account or a real SPL Token / Token-2022 mint. Specify supply, decimals, authority, eligibility, anti-abuse and redemption policy.
  - Acceptance: product decision + token flow diagram + tests; UI never labels an event-only reward as a minted token.

### Phase 2 — Complete the on-chain donation workflow (P1)

- [ ] **FTF-SOL-009 — User registration and roles.** Implement secure registration, profile updates, admin initialization/rotation and verification. Define whether one wallet can hold multiple roles and how role changes are authorized.
  - Acceptance: donor, NGO, volunteer and admin scenarios work on local validator; unauthorized role changes fail.
- [ ] **FTF-SOL-010 — Donation creation and discovery.** Validate quantity, units, category, expiry, storage constraints, image/content hashes and maximum string/vector sizes. Add pagination/indexing strategy for reading available donations.
  - Acceptance: valid donation is stored once, indexed by PDA/event and visible to authorized app users; invalid/expired data is rejected.
- [ ] **FTF-SOL-011 — NGO matching.** Ensure only eligible NGOs/admins can match, prevent double matching, and bind the selected NGO account to the actual signer.
  - Acceptance: two competing match transactions cannot both claim the same donation; tests verify the winner and rejection.
- [ ] **FTF-SOL-012 — Pickup lifecycle.** Validate volunteer role and assignment, pickup time, allowed transitions and actual quantity; prevent unassigned volunteers from completing pickup.
  - Acceptance: only the assigned volunteer (or explicitly authorized role) can complete; duplicate completion and quantity abuse fail.
- [ ] **FTF-SOL-013 — Delivery lifecycle.** Validate delivery assignment, recipient confirmation, received quantity and evidence hash; define partial delivery, cancellation, expiry and dispute flows.
  - Acceptance: delivered state requires the defined confirmation conditions; incomplete/invalid delivery cannot silently become delivered.
- [ ] **FTF-SOL-014 — Cancellation, expiry and dispute policy.** Add explicit terminal/exception states and authorized transition rules rather than leaving records stuck indefinitely.
  - Acceptance: each terminal state has a documented actor, precondition and event; tests cover every transition.
- [ ] **FTF-SOL-015 — Reputation and rewards.** Make reputation changes attributable and policy-bound; prevent arbitrary user-controlled score inflation. Implement actual SPL minting only if the token decision requires it.
  - Acceptance: score changes are derived from valid lifecycle events or a narrowly authorized dispute/admin process; replay cannot award twice.

### Phase 3 — Flutter wallet and program client (P1)

- [ ] **FTF-SOL-016 — Select and spike the Flutter Solana stack.** Compare maintained Flutter RPC/transaction libraries and wallet connection/signing options for Android and iOS. Confirm Anchor 0.31.1 IDL compatibility, PDA derivation, transaction serialization, simulation and signing support before choosing packages.
  - Acceptance: a small proof-of-concept connects a real Devnet wallet, reads balance, derives a PDA, signs and submits a harmless transaction on each supported platform.
- [ ] **FTF-SOL-017 — Add a wallet abstraction.** Create `WalletRepository` / `SolanaWalletProvider` interfaces for connect, disconnect, public key, sign transaction/message, network and session state. Implement platform adapters; do not store seed phrases/private keys.
  - Acceptance: UI depends on interfaces, not a specific wallet vendor; rejected/cancelled signatures and disconnected sessions are handled.
- [ ] **FTF-SOL-018 — Generate and integrate the Anchor client.** Generate IDL/types from the built program; add typed instruction builders and shared PDA seed definitions. Do not manually duplicate account layouts in multiple places.
  - Acceptance: Flutter can derive the same user/donation PDAs as Anchor tests and build instructions with the generated schema.
- [ ] **FTF-SOL-019 — Replace the placeholder service.** Move the template out of `solana-contract/flutter_config.dart` into app feature/core layers. Implement RPC config, commitment, retries, blockhash expiry, simulation, send/confirm, structured errors and explorer links.
  - Acceptance: no placeholder PDA strings, print-only methods or TODO transaction stubs remain in the production service.
- [ ] **FTF-SOL-020 — Link Firebase identity to wallet.** Add nonce-based signed-message verification (server-side), expiry/replay protection and unlink/relink behavior. Keep email and Firebase UID off-chain.
  - Acceptance: a Firebase user can prove control of a wallet; a forged address or replayed signature is rejected.
- [ ] **FTF-SOL-021 — Build the donation UI integration.** Add connect-wallet state, role onboarding, create donation, donation detail/status, NGO match, pickup and delivery confirmation. Show pending, submitted, confirmed, failed and expired transaction states distinctly.
  - Acceptance: user can complete the intended flow from Flutter without CLI, manual PDA entry or hard-coded test wallet.
- [ ] **FTF-SOL-022 — Keep Firebase and chain consistent.** Use transaction signature + PDA as durable references; implement idempotent Cloud Function/indexer processing of Anchor events. Treat chain as source of truth for on-chain state and Firebase as query/notification projection.
  - Acceptance: retries do not duplicate records/notifications; reconciliation can repair a missed event; UI distinguishes pending chain confirmation from indexed state.
- [ ] **FTF-SOL-023 — Evidence and media handling.** Upload photos to Firebase Storage, store content hash/opaque reference on-chain, and apply access controls to private media. Do not store private download URLs on-chain.
  - Acceptance: media integrity can be checked against its hash without exposing private storage credentials or user data.

### Phase 4 — End-to-end quality and Devnet release (P0/P1)

- [ ] **FTF-SOL-024 — Local end-to-end test.** Exercise donor registration → create donation → NGO match → volunteer pickup → delivery → final state and reputation. Include negative paths and multiple wallets.
  - Acceptance: repeatable CI run proves full lifecycle; tests assert account data, events, authorization and final balances/fees where relevant.
- [ ] **FTF-SOL-025 — Flutter integration tests.** Test Android and iOS wallet connect/sign/cancel, network mismatch, low SOL, RPC timeout, blockhash expiry, app background/resume and duplicate taps.
  - Acceptance: automated tests plus recorded manual test matrix on real devices/emulators.
- [ ] **FTF-SOL-026 — Deploy to Devnet.** Build from a clean commit, verify artifact and Program ID, deploy with a controlled upgrade authority and record deployment signature/slot/program account.
  - Acceptance: `solana program show <PROGRAM_ID> --url devnet` confirms the executable and upgrade authority; Explorer link and deployment metadata are committed. A config value alone is not proof of deployment.
- [ ] **FTF-SOL-027 — Run real Devnet acceptance flow.** Use separate donor, NGO, volunteer and admin wallets; complete the entire flow from the Flutter app and save transaction signatures/screenshots/logs.
  - Acceptance: every critical transaction is confirmed on Devnet and independently inspectable in Explorer; no mock data or local-only shortcut is used.
- [ ] **FTF-SOL-028 — CI and repository hygiene.** Add contract build/test, IDL drift check, Dart format/analyze/test and secret scanning. Remove generated `target/` artifacts from version control and ignore build outputs/keypairs.
  - Acceptance: clean CI passes from checkout; no keypairs, seed phrases, RPC secrets or build binaries are committed.
- [ ] **FTF-SOL-029 — Operational runbook.** Document RPC provider/fallback, rate limits, transaction retry policy, monitoring, event indexing, reconciliation, upgrade authority, incident response and recovery.
  - Acceptance: another developer can deploy, verify, diagnose and recover the Devnet app using only the docs and authorized secrets.

### Phase 5 — Pilot and optional production hardening (P2/P3)

- [ ] **FTF-SOL-030 — Pilot with controlled participants.** Run a limited Devnet pilot with test identities and collect UX, reliability and fee feedback.
- [ ] **FTF-SOL-031 — Independent security review.** Review the final deployed source, IDL, account constraints, upgrade authority and wallet signing UX before any real-value or public production rollout.
- [ ] **FTF-SOL-032 — Mainnet decision gate.** Decide whether mainnet is justified; repeat privacy/legal/security review, create separate production config and key management, and plan upgrade authority governance.
- [ ] **FTF-SOL-033 — Optional reward token.** If approved, deploy and test the chosen SPL Token / Token-2022 mint, metadata, authority and distribution policy. Otherwise keep rewards as non-transferable reputation points.
- [ ] **FTF-SOL-034 — Performance and cost tuning.** Measure transaction sizes, account rent, compute units, RPC reliability and indexing lag using real test runs; optimize only from measured evidence.

---

## Suggested implementation order

1. **First close P0:** FTF-SOL-001 through 008. Do not connect real users to the current contract before privacy and authority checks are complete.
2. **Then make the lifecycle correct:** FTF-SOL-009 through 015.
3. **Then connect Flutter:** FTF-SOL-016 through 023.
4. **Then prove it:** FTF-SOL-024 through 029, including a full Devnet run.
5. **Only after that:** pilot and production decisions.

## Definition of “completely functional”

Feed the Future is not complete merely because the Rust program compiles or a Program ID appears in config. Completion requires all of the following:

- reproducible clean build and passing contract tests;
- reviewed role/authority constraints and privacy-safe on-chain schema;
- a real, verified Devnet deployment whose Program ID matches source, Anchor config, IDL and Flutter config;
- real wallet connect/signing on Android and iOS, without exposing private keys;
- complete donation → match → pickup → delivery lifecycle from the Flutter UI;
- Firebase projection/indexing that is idempotent and reconcilable;
- transaction signatures, Explorer links, automated test results and a reproducible demo/evidence pack;
- documented operational ownership and no committed secrets/build artifacts.

## Reference documentation

- [Solana — Build your first program](https://solana.com/docs/intro/quick-start/build-first-program)
- [Solana — Deploying programs](https://solana.com/docs/programs/deploying)
- [Solana — Frontend and client architecture](https://solana.com/docs/frontend)
- [Solana Mobile Wallet Adapter](https://github.com/solana-mobile/mobile-wallet-adapter)

---
*Roadmap created from a read-only inspection of the repository's default branch. Checklist items are intentionally unchecked; no deployment, tests or implementation work is claimed by this document.*
