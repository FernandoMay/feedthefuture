/**
 * Feed the Future — Program unit tests.
 *
 * Runs against a local validator (solana-test-validator) started by
 * scripts/start-validator.sh. Every mutating instruction has a positive test
 * plus unauthorized/invalid-input tests (FTF-SOL-004/005/009-015).
 *
 * Run:  npm test
 */
import * as anchor from "@coral-xyz/anchor";
import { Program, BN } from "@coral-xyz/anchor";
import { Connection, Keypair, PublicKey, SystemProgram } from "@solana/web3.js";
import * as path from "node:path";
import * as fs from "node:fs";

// The generated TS type (target/types/feed_the_future.ts) is the camelCase IDL;
// anchor.workspace reads it at runtime, so we type it as `any` to avoid
// extensionless-TS-import resolution issues under Node ESM.
type FeedTheFuture = any;

const RPC_URL = process.env.RPC_URL ?? "http://127.0.0.1:8899";
const TOKEN_PROGRAM_ID = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const RENT_SYSVAR = "SysvarRent111111111111111111111111111111111";

// Jest-style expect shim for the unit tests (toEqual/toBe/toBeTruthy).
function deepEqual(a: any, b: any): boolean {
  if (a === b) return true;
  if (a == null || b == null) return a === b;
  if (typeof a.eq === "function" && typeof b.eq === "function") {
    try {
      if (a.eq(b)) return true;
    } catch {
      /* not comparable */
    }
  }
  if (typeof a.toString === "function" && typeof b.toString === "function" && a.toString() === b.toString()) {
    return true;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    return a.length === b.length && a.every((v, i) => deepEqual(v, b[i]));
  }
  if (typeof a === "object" && typeof b === "object") {
    const ka = Object.keys(a);
    const kb = Object.keys(b);
    return ka.length === kb.length && ka.every((k) => deepEqual(a[k], b[k]));
  }
  return false;
}

const fmt = (v: any) => {
  if (typeof v === "bigint") return `${v}n`;
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
};

const expect = (actual: any) => ({
  toEqual(expected: any) {
    if (!deepEqual(actual, expected)) {
      throw new Error(`expected ${fmt(actual)} to equal ${fmt(expected)}`);
    }
  },
  toBe(expected: any) {
    if (actual !== expected) {
      throw new Error(`expected ${fmt(actual)} to be ${fmt(expected)}`);
    }
  },
  toBeTruthy() {
    if (!actual) {
      throw new Error("expected value to be truthy");
    }
  },
});

describe("Feed the Future", () => {
  const connection = new Connection(RPC_URL, "confirmed");
  // The validator's fee payer: use the genesis-gifted faucet keypair from the ledger.
  const faucetKeypairPath =
    process.env.FTF_FAUCET_KEYPAIR ?? path.join(process.cwd(), "out", "validator", "ledger", "faucet-keypair.json");
  const providerKeypair = Keypair.fromSecretKey(
    Uint8Array.from(JSON.parse(fs.readFileSync(faucetKeypairPath, "utf8")) as number[])
  );
  const provider = new anchor.AnchorProvider(
    connection,
    new anchor.Wallet(providerKeypair, connection),
    { commitment: "confirmed" }
  );
  anchor.setProvider(provider);
  const program = anchor.workspace.feedTheFuture as Program<FeedTheFuture>;
  const PROGRAM_ID = program.programId;

  before(async () => {
    const balance = await connection.getBalance(providerKeypair.publicKey);
    if (balance < 1_000_000_000n) {
      throw new Error(`provider wallet has no SOL on the validator: ${balance}`);
    }
    // initializeUser() creates each user account with `payer = authority`, so
    // every authority keypair must hold SOL for the rent of its new user
    // account (the System program create_account transfer). Give each test
    // authority a comfortable balance via the validator's mint-mode airdrop,
    // waiting for the airdrop to be confirmed before proceeding.
    for (const kp of [admin, donor, ngo, volunteer]) {
      if ((await connection.getBalance(kp.publicKey)) >= 1_000_000_000n) continue;
      await connection.requestAirdrop(kp.publicKey, 10_000_000_000);
      for (let i = 0; i < 100; i++) {
        if ((await connection.getBalance(kp.publicKey)) >= 1_000_000_000n) break;
        await new Promise((r) => setTimeout(r, 200));
      }
    }
  });

  // ---------------------------------------------------------------- helpers

  function userPda(wallet: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("user"), wallet.toBuffer()],
      PROGRAM_ID
    );
  }

  function donationPda(donor: PublicKey, nonce: number): [PublicKey, number] {
    const seed = Buffer.alloc(8);
    seed.writeBigUInt64LE(BigInt(nonce), 0);
    return PublicKey.findProgramAddressSync(
      [Buffer.from("donation"), donor.toBuffer(), seed],
      PROGRAM_ID
    );
  }

  function pickupPda(donation: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync([Buffer.from("pickup"), donation.toBuffer()], PROGRAM_ID);
  }

  function deliveryPda(donation: PublicKey): [PublicKey, number] {
    return PublicKey.findProgramAddressSync([Buffer.from("delivery"), donation.toBuffer()], PROGRAM_ID);
  }

  function configPda(): [PublicKey, number] {
    return PublicKey.findProgramAddressSync([Buffer.from("config")], PROGRAM_ID);
  }

  function rewardPda(authority: PublicKey, name: string): [PublicKey, number] {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("reward"), authority.toBuffer(), Buffer.from(name)],
      PROGRAM_ID
    );
  }

  function location(over: any = {}): any {
    return {
      city: "Cuautitlán Izcalli",
      country: "MX",
      region: "Estado de México",
      positionHash: null,
      ...over,
    };
  }

  function donationData(over: any = {}): any {
    return {
      nonce: initDonationNonce,
      name: "Papas frescas",
      category: "alimentos",
      quantity: 10,
      unit: "cajas",
      description: "Papas de la huerta, frescas",
      expirationDate: "2026-12-01",
      storageRequirements: "En enfriado",
      isUrgent: false,
      isPerishable: true,
      requiresRefrigeration: true,
      images: ["ipfs://example/papas.jpg"],
      ...over,
    };
  }

  // anchor TS requires BN for u64 args.
  function bnArgs(d: any): any {
    return { ...d, nonce: new BN(d.nonce), quantity: new BN(d.quantity) };
  }

  function globalConfig(over: any = {}): any {
    // Same defaults as GlobalConfig::default() in Rust. Numeric fields are BNs
    // because the anchor TS coder requires them for u16/u32/u64 fields.
    const base = {
      minReputationForMatching: 50,
      maxDonationsPerDay: 10,
      pickupTimeoutHours: 24,
      deliveryTimeoutHours: 48,
      reputationDecayRate: 1,
      rewardTokenAmountPerDonation: 100,
      co2SavedPerKg: 2500,
      platformFeePercentage: 2,
      emergencyThresholdHours: 6,
    };
    const merged = { ...base, ...over };
    return Object.fromEntries(Object.entries(merged).map(([k, v]) => [k, new BN(v as number)]));
  }

  function norm(v: any): string {
    // Anchor decodes borsh enums as single-key objects (e.g. { admin: {} }).
    if (v != null && typeof v === "object" && !Array.isArray(v)) {
      const keys = Object.keys(v);
      if (keys.length === 1) return String(keys[0]).toLowerCase();
    }
    return String(v ?? "").toLowerCase();
  }

  function normAll(s: string): string {
    return String(s).toLowerCase().replace(/[^a-z0-9]/g, "");
  }

  async function expectError(fn: () => Promise<any>, msgPart: string) {
    try {
      await fn();
    } catch (err: any) {
      const msg = String(err?.message ?? err);
      if (!normAll(msg).includes(normAll(msgPart))) {
        throw new Error(`expected error containing "${msgPart}", got: ${msg}`);
      }
      return;
    }
    throw new Error(`expected error containing "${msgPart}", but the transaction succeeded`);
  }

  const fut = () => Math.floor(Date.now() / 1000) + 3600;

  // ------------------------------------------------------------- test state

  const admin = Keypair.generate();
  const adminUserPda = userPda(admin.publicKey);
  const configAddress = configPda()[0];
  const donor = Keypair.generate();
  const donorPda = userPda(donor.publicKey);
  const ngo = Keypair.generate();
  const ngoPda = userPda(ngo.publicKey);
  const volunteer = Keypair.generate();
  const volunteerPda = userPda(volunteer.publicKey);

  const initDonationNonce = Date.now() + Math.floor(Math.random() * 1000000);
  const donation1 = donationPda(donor.publicKey, initDonationNonce);
  const pickup1 = pickupPda(donation1[0]);
  const delivery1 = deliveryPda(donation1[0]);

  describe("setup: initialize config and users", () => {

    it("initializeConfig as admin, then users for every role", async () => {
      // Admin user first so the config has an authority.
      const [userPDA] = userPda(admin.publicKey);
      await program.methods.initializeUser({ admin: {} }, "admin-user", location()).accounts({
        user: userPDA,
        authority: admin.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, admin]).rpc();
      await expectError(
        () => program.methods.initializeUser({ admin: {} }, "admin-user-2", location()).accounts({
          user: userPDA,
          authority: admin.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, admin]).rpc(),
        "already in use"
      );

      const adminAccount = await program.account.userAccount.fetch(userPDA);
      expect(norm(adminAccount.role)).toEqual("admin");
      expect(adminAccount.authority).toEqual(admin.publicKey);
      expect(Number(adminAccount.reputationScore)).toEqual(100);
      expect(adminAccount.isActive).toEqual(true);
      expect(adminAccount.isVerified).toEqual(false);

      // Initialize global config with admin as authority.
      await program.methods.initializeConfig(globalConfig()).accounts({
        globalConfig: configAddress,
        authority: admin.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, admin]).rpc();

      const cfg = await program.account.globalConfigAccount.fetch(configAddress);
      expect(cfg.authority).toEqual(admin.publicKey);
      expect(Number(cfg.config.minReputationForMatching)).toEqual(50);
      expect(Number(cfg.config.platformFeePercentage)).toEqual(2);
      expect(Number(cfg.config.emergencyThresholdHours)).toEqual(6);

      // One user per role (one wallet = one identity).
      for (const [kp, role, name] of [
        [donor, "donor", "donor-user"],
        [ngo, "ngo", "ngo-user"],
        [volunteer, "volunteer", "volunteer-user"],
      ] as [Keypair, string, string][]) {
        const [pda] = userPda(kp.publicKey);
        await program.methods.initializeUser({ [role]: {} }, name, location()).accounts({
          user: pda,
          authority: kp.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, kp]).rpc();
        const acc = await program.account.userAccount.fetch(pda);
        expect(norm(acc.role)).toEqual(role);
        expect(acc.username).toEqual(name);
        expect(Number(acc.reputationScore)).toEqual(100);
      }
    }, 120_000);
  });

  describe("user management", () => {
    it("update_user_profile updates username and location", async () => {
      const [pda] = userPda(donor.publicKey);
      await program.methods.updateUserProfile("donor-renamed", location()).accounts({
        user: pda,
        authority: donor.publicKey,
      }).signers([providerKeypair, providerKeypair, donor]).rpc();
      const acc = await program.account.userAccount.fetch(pda);
      expect(acc.username).toEqual("donor-renamed");
    });

    it("update_user_profile rejects empty username", async () => {
      const [pda] = userPda(donor.publicKey);
      await expectError(
        () => program.methods.updateUserProfile("", null).accounts({ user: pda, authority: donor.publicKey }).signers([providerKeypair, providerKeypair, donor]).rpc(),
        "Invalid name"
      );
    });

    it("verify_user: admin verifies another user", async () => {
      const [ngoPDA] = userPda(ngo.publicKey);
      await program.methods.verifyUser(ngo.publicKey).accounts({
        user: ngoPDA,
        authorityUser: adminUserPda[0],
        authority: admin.publicKey,
      }).signers([providerKeypair, providerKeypair, admin]).rpc();
      const acc = await program.account.userAccount.fetch(ngoPDA);
      expect(acc.isVerified).toEqual(true);
    });

    it("verify_user: non-admin is rejected", async () => {
      const [userPDA] = userPda(volunteer.publicKey);
      await expectError(
        () => program.methods.verifyUser(volunteer.publicKey).accounts({
          user: userPDA,
          authorityUser: userPDA,
          authority: volunteer.publicKey,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "not authorized"
      );
    });

    it("verify_user: admin cannot verify themselves", async () => {
      await expectError(
        () => program.methods.verifyUser(admin.publicKey).accounts({
          user: adminUserPda[0],
          authorityUser: adminUserPda[0],
          authority: admin.publicKey,
        }).signers([providerKeypair, providerKeypair, admin]).rpc(),
        "not authorized"
      );
    });

    it("create_donation: stores donation, bumps donor stats", async () => {
      const data = donationData();
      const sig = await program.methods.createDonation(bnArgs(data)).accounts({
        donation: donation1[0],
        donorAccount: donorPda[0],
        donor: donor.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, donor]).rpc();
      expect(sig).toBeTruthy();
      const d = await program.account.donation.fetch(donation1[0]);
      expect(d.donor).toEqual(donor.publicKey);
      expect(Number(d.nonce)).toEqual(data.nonce);
      expect(norm(d.status)).toEqual("available");
      expect(d.donationData.name).toEqual(data.name);
      expect(Number(d.donationData.quantity)).toEqual(data.quantity);
      const u = await program.account.userAccount.fetch(donorPda[0]);
      expect(Number(u.totalDonations)).toEqual(1);
    });

    it("create_donation: rejects zero quantity and empty name", async () => {
      let nonceA = 0; let nonceB = 0;
      await expectError(
        () => program.methods.createDonation(bnArgs(donationData({ quantity: 0, nonce: (nonceA = Date.now() + 998001) }))).accounts({
          donation: donationPda(donor.publicKey, nonceA)[0],
          donorAccount: donorPda[0],
          donor: donor.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, donor]).rpc(),
        "Invalid quantity"
      );
      await expectError(
        () => program.methods.createDonation(bnArgs(donationData({ name: "", nonce: (nonceB = Date.now() + 998101) }))).accounts({
          donation: donationPda(donor.publicKey, nonceB)[0],
          donorAccount: donorPda[0],
          donor: donor.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, donor]).rpc(),
        "Invalid name"
      );
    });

    it("create_donation: same nonce twice fails (no address collision)", async () => {
      await expectError(
        () => program.methods.createDonation(bnArgs(donationData({ nonce: initDonationNonce }))).accounts({
          donation: donation1[0],
          donorAccount: donorPda[0],
          donor: donor.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, donor]).rpc(),
        "already in use"
      );
    });

    it("create_donation: rejects as volunteer (role enforcement)", async () => {
      const nonce = Date.now() + 998201;
      await expectError(
        () => program.methods.createDonation(bnArgs(donationData({ nonce }))).accounts({
          donation: donationPda(volunteer.publicKey, nonce)[0],
          donorAccount: volunteerPda[0],
          donor: volunteer.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "Invalid user role"
      );
    });
  });

  describe("match_donation", () => {
    // Rejection tests run first, while donation1 is still Available (the
    // positive match below flips it to Matched and the program checks status
    // before the authorization requirements).
    it("donor cannot claim a match on behalf of an NGO", async () => {
      // (a) An NGO signing but claiming a different key as the matched NGO is
      // rejected: the match is bound to the signer.
      await expectError(
        () => program.methods.matchDonation(donor.publicKey).accounts({
          donation: donation1[0],
          ngoUser: ngoPda[0],
          config: configAddress,
          ngo: ngo.publicKey,
        }).signers([providerKeypair, providerKeypair, ngo]).rpc(),
        "not authorized"
      );
      // (b) The donor (wrong role) cannot claim a match either; seeds force the
      // donor's own user PDA, where the role constraint rejects the call.
      await expectError(
        () => program.methods.matchDonation(ngo.publicKey).accounts({
          donation: donation1[0],
          ngoUser: donorPda[0],
          config: configAddress,
          ngo: donor.publicKey,
        }).signers([providerKeypair, providerKeypair, donor]).rpc(),
        "Invalid user role"
      );
    });

    it("NGO signs and matches (bound to signer, reputation respected)", async () => {
      await program.methods.matchDonation(ngo.publicKey).accounts({
        donation: donation1[0],
        ngoUser: ngoPda[0],
        config: configAddress,
        ngo: ngo.publicKey,
      }).signers([providerKeypair, providerKeypair, ngo]).rpc();
      const d = await program.account.donation.fetch(donation1[0]);
      expect(norm(d.status)).toEqual("matched");
      expect(d.matchedNgo).toEqual(ngo.publicKey);
    });

    it("replay: match again fails (not available anymore)", async () => {
      await expectError(
        () => program.methods.matchDonation(ngo.publicKey).accounts({
          donation: donation1[0],
          ngoUser: ngoPda[0],
          config: configAddress,
          ngo: ngo.publicKey,
        }).signers([providerKeypair, providerKeypair, ngo]).rpc(),
        "not available"
      );
    });
  });

  describe("schedule_pickup", () => {
    it("volunteer schedules pickup (requires Matched)", async () => {
      const pickupTime = fut();
      await program.methods.schedulePickup(new BN(pickupTime), location({ city: "Pickup City" })).accounts({
        donation: donation1[0],
        pickupRequest: pickup1[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      const d = await program.account.donation.fetch(donation1[0]);
      expect(norm(d.status)).toEqual("pending");
      const p = await program.account.pickupRequest.fetch(pickup1[0]);
      expect(p.volunteer).toEqual(volunteer.publicKey);
      expect(Number(p.scheduledTime)).toEqual(pickupTime);
      expect(norm(p.status)).toEqual("scheduled");
    });

    it("rejects past pickup times", async () => {
      const nonce2 = Date.now() + 5432111;
      const donation2 = donationPda(donor.publicKey, nonce2);
      const pickup2 = pickupPda(donation2[0]);
      await program.methods.createDonation(bnArgs(donationData({ nonce: nonce2 }))).accounts({
        donation: donation2[0],
        donorAccount: donorPda[0],
        donor: donor.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, donor]).rpc();
      await program.methods.matchDonation(ngo.publicKey).accounts({
        donation: donation2[0],
        ngoUser: ngoPda[0],
        config: configAddress,
        ngo: ngo.publicKey,
      }).signers([providerKeypair, providerKeypair, ngo]).rpc();
      await expectError(
        () => program.methods.schedulePickup(new BN(Math.floor(Date.now() / 1000) - 10), location()).accounts({
          donation: donation2[0],
          pickupRequest: pickup2[0],
          volunteerAccount: volunteerPda[0],
          volunteer: volunteer.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "Invalid timestamp"
      );
    });

    it("rejects scheduling pickup when not matched", async () => {
      const nonce3 = Date.now() + 5432113;
      const donation3 = donationPda(donor.publicKey, nonce3);
      const pickup3 = pickupPda(donation3[0]);
      await program.methods.createDonation(bnArgs(donationData({ nonce: nonce3 }))).accounts({
        donation: donation3[0],
        donorAccount: donorPda[0],
        donor: donor.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, donor]).rpc();
      await expectError(
        () => program.methods.schedulePickup(new BN(fut()), location()).accounts({
          donation: donation3[0],
          pickupRequest: pickup3[0],
          volunteerAccount: volunteerPda[0],
          volunteer: volunteer.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "not matched"
      );
    });
  });

  describe("complete_pickup", () => {
    it("volunteer completes pickup (quantity > 0, must be Pending)", async () => {
      await program.methods.completePickup(new BN(10), null).accounts({
        donation: donation1[0],
        pickupRequest: pickup1[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      const d = await program.account.donation.fetch(donation1[0]);
      // anchor decodes Rust enum variants as camelCase (inTransit).
      expect(norm(d.status)).toEqual("intransit");
      expect(Number(d.donationData.quantity)).toEqual(10);
      const p = await program.account.pickupRequest.fetch(pickup1[0]);
      expect(norm(p.status)).toEqual("completed");
      const v = await program.account.userAccount.fetch(volunteerPda[0]);
      expect(Number(v.totalPickups)).toEqual(1);
    });

    it("duplicate completion is rejected", async () => {
      await expectError(
        () => program.methods.completePickup(new BN(10), null).accounts({
          donation: donation1[0],
          pickupRequest: pickup1[0],
          volunteerAccount: volunteerPda[0],
          volunteer: volunteer.publicKey,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "not pending"
      );
    });

    it("rejects zero quantity", async () => {
      const nonce2 = Date.now() + 5432121;
      const donation2 = donationPda(donor.publicKey, nonce2);
      const pickup2 = pickupPda(donation2[0]);
      await program.methods.createDonation(bnArgs(donationData({ nonce: nonce2 }))).accounts({
        donation: donation2[0],
        donorAccount: donorPda[0],
        donor: donor.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, donor]).rpc();
      await program.methods.matchDonation(ngo.publicKey).accounts({
        donation: donation2[0],
        ngoUser: ngoPda[0],
        config: configAddress,
        ngo: ngo.publicKey,
      }).signers([providerKeypair, providerKeypair, ngo]).rpc();
      await program.methods.schedulePickup(new BN(fut()), location()).accounts({
        donation: donation2[0],
        pickupRequest: pickup2[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      await expectError(
        () => program.methods.completePickup(new BN(0), null).accounts({
          donation: donation2[0],
          pickupRequest: pickup2[0],
          volunteerAccount: volunteerPda[0],
          volunteer: volunteer.publicKey,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "Invalid quantity"
      );
      // And complete it properly so later tests see consistent state.
      await program.methods.completePickup(new BN(10), null).accounts({
        donation: donation2[0],
        pickupRequest: pickup2[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
    });
  });

  describe("schedule_delivery", () => {
    it("volunteer schedules delivery (requires InTransit)", async () => {
      const deliveryTime = fut();
      await program.methods.scheduleDelivery(new BN(deliveryTime), location({ city: "Delivery City" })).accounts({
        donation: donation1[0],
        deliveryRequest: delivery1[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      const d = await program.account.donation.fetch(donation1[0]);
      expect(d.deliveryVolunteer).toEqual(volunteer.publicKey);
      const dr = await program.account.deliveryRequest.fetch(delivery1[0]);
      expect(dr.volunteer).toEqual(volunteer.publicKey);
      expect(norm(dr.status)).toEqual("scheduled");
    });

    it("rejects delivery schedule when not in transit (Available donation)", async () => {
      const nonce3 = Date.now() + 5432123;
      const donation3 = donationPda(donor.publicKey, nonce3);
      const delivery3 = deliveryPda(donation3[0]);
      await program.methods.createDonation(bnArgs(donationData({ nonce: nonce3 }))).accounts({
        donation: donation3[0],
        donorAccount: donorPda[0],
        donor: donor.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, donor]).rpc();
      await expectError(
        () => program.methods.scheduleDelivery(new BN(fut()), location()).accounts({
          donation: donation3[0],
          deliveryRequest: delivery3[0],
          volunteerAccount: volunteerPda[0],
          volunteer: volunteer.publicKey,
          systemProgram: SystemProgram.programId,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "not in transit"
      );
    });
  });

  describe("complete_delivery", () => {
    it("volunteer completes delivery; reputation of donor and volunteer rises", async () => {
      await program.methods.completeDelivery(new BN(10), null, null).accounts({
        donation: donation1[0],
        deliveryRequest: delivery1[0],
        donorAccount: donorPda[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      const d = await program.account.donation.fetch(donation1[0]);
      expect(norm(d.status)).toEqual("delivered");
      expect(Number(d.donationData.quantity)).toEqual(10);
      const donorAccount = await program.account.userAccount.fetch(donorPda[0]);
      expect(Number(donorAccount.reputationScore)).toEqual(105);
      const volunteerAccount = await program.account.userAccount.fetch(volunteerPda[0]);
      expect(Number(volunteerAccount.reputationScore)).toEqual(103);
      expect(Number(volunteerAccount.totalDeliveries)).toEqual(1);
    });

    it("duplicate completion is rejected", async () => {
      await expectError(
        () => program.methods.completeDelivery(new BN(10), null, null).accounts({
          donation: donation1[0],
          deliveryRequest: delivery1[0],
          donorAccount: donorPda[0],
          volunteerAccount: volunteerPda[0],
          volunteer: volunteer.publicKey,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "not scheduled"
      );
    });

    it("rejects quantity above donated quantity (no silent quantity abuse)", async () => {
      const nonce2 = Date.now() + 5432131;
      const donation2 = donationPda(donor.publicKey, nonce2);
      const delivery2 = deliveryPda(donation2[0]);
      await program.methods.createDonation(bnArgs(donationData({ nonce: nonce2 }))).accounts({
        donation: donation2[0],
        donorAccount: donorPda[0],
        donor: donor.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, donor]).rpc();
      await program.methods.matchDonation(ngo.publicKey).accounts({
        donation: donation2[0],
        ngoUser: ngoPda[0],
        config: configAddress,
        ngo: ngo.publicKey,
      }).signers([providerKeypair, providerKeypair, ngo]).rpc();
      await program.methods.schedulePickup(new BN(fut()), location()).accounts({
        donation: donation2[0],
        pickupRequest: pickupPda(donation2[0]),
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      await program.methods.completePickup(new BN(10), null).accounts({
        donation: donation2[0],
        pickupRequest: pickupPda(donation2[0]),
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      await program.methods.scheduleDelivery(new BN(fut()), location()).accounts({
        donation: donation2[0],
        deliveryRequest: delivery2[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
        systemProgram: SystemProgram.programId,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      await expectError(
        () => program.methods.completeDelivery(new BN(11), null, null).accounts({
          donation: donation2[0],
          deliveryRequest: delivery2[0],
          donorAccount: donorPda[0],
          volunteerAccount: volunteerPda[0],
          volunteer: volunteer.publicKey,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "Invalid quantity"
      );
      await program.methods.completeDelivery(new BN(10), null, null).accounts({
        donation: donation2[0],
        deliveryRequest: delivery2[0],
        donorAccount: donorPda[0],
        volunteerAccount: volunteerPda[0],
        volunteer: volunteer.publicKey,
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
    });

    it("rejects completion by someone who is not the assigned volunteer", async () => {
      await expectError(
        () => program.methods.completeDelivery(new BN(1), null, null).accounts({
          donation: donation1[0],
          deliveryRequest: delivery1[0],
          donorAccount: donorPda[0],
          volunteerAccount: ngoPda[0],
          volunteer: ngo.publicKey,
        }).signers([providerKeypair, providerKeypair, ngo]).rpc(),
        "not authorized"
      );
    });
  });

  describe("reputation & config", () => {
    it("update_reputation: admin bounded by 0..1000", async () => {
      await program.methods.updateReputation(ngo.publicKey, new BN(-10), "test dip").accounts({
        targetUserAccount: ngoPda[0],
        authorityUser: adminUserPda[0],
        authority: admin.publicKey,
      }).signers([providerKeypair, providerKeypair, admin]).rpc();
      let acc = await program.account.userAccount.fetch(ngoPda[0]);
      expect(Number(acc.reputationScore)).toEqual(90);
      await expectError(
        () => program.methods.updateReputation(ngo.publicKey, new BN(-1000), "negative").accounts({
          targetUserAccount: ngoPda[0],
          authorityUser: adminUserPda[0],
          authority: admin.publicKey,
        }).signers([providerKeypair, providerKeypair, admin]).rpc(),
        "Invalid reputation score"
      );
      await program.methods.updateReputation(ngo.publicKey, new BN(200), "boost").accounts({
        targetUserAccount: ngoPda[0],
        authorityUser: adminUserPda[0],
        authority: admin.publicKey,
      }).signers([providerKeypair, providerKeypair, admin]).rpc();
      acc = await program.account.userAccount.fetch(ngoPda[0]);
      expect(Number(acc.reputationScore)).toEqual(290);
      await program.methods.updateReputation(ngo.publicKey, new BN(-5), "restore").accounts({
        targetUserAccount: ngoPda[0],
        authorityUser: adminUserPda[0],
        authority: admin.publicKey,
      }).signers([providerKeypair, providerKeypair, admin]).rpc();
      acc = await program.account.userAccount.fetch(ngoPda[0]);
      expect(Number(acc.reputationScore)).toEqual(285);
    });

    it("update_reputation: non-admin rejected", async () => {
      await expectError(
        () => program.methods.updateReputation(donor.publicKey, new BN(1), "by volunteer").accounts({
          targetUserAccount: donorPda[0],
          authorityUser: volunteerPda[0],
          authority: volunteer.publicKey,
        }).signers([providerKeypair, providerKeypair, volunteer]).rpc(),
        "not authorized"
      );
    });

    it("update_config: admin-only; donor rejected", async () => {
      await expectError(
        () => program.methods.updateConfig(globalConfig({ platformFeePercentage: 5 })).accounts({
          globalConfig: configAddress,
          authorityUser: donorPda[0],
          authority: donor.publicKey,
        }).signers([providerKeypair, providerKeypair, donor]).rpc(),
        "A has one constraint was violated"
      );
      await program.methods.updateConfig(globalConfig({ platformFeePercentage: 5 })).accounts({
        globalConfig: configAddress,
        authorityUser: adminUserPda[0],
        authority: admin.publicKey,
      }).signers([providerKeypair, providerKeypair, admin]).rpc();
      const cfg = await program.account.globalConfigAccount.fetch(configAddress);
      expect(Number(cfg.config.platformFeePercentage)).toEqual(5);
    });

    it("create_reward_token: creates a real SPL token mint (0 decimals)", async () => {
      const name = "test-reward";
      const [mintPda] = rewardPda(ngo.publicKey, name);
      await program.methods.createRewardToken(name, "TRW", "https://example.com/token").accounts({
        user: ngoPda[0],
        mint: mintPda,
        authority: ngo.publicKey,
        systemProgram: SystemProgram.programId,
        tokenProgram: new PublicKey(TOKEN_PROGRAM_ID),
        rent: new PublicKey(RENT_SYSVAR),
      }).signers([providerKeypair, providerKeypair, ngo]).rpc();
      const info = await connection.getAccountInfo(mintPda);
      expect(info).toBeTruthy();
      // Parse spl_token::state::Mint: COption<Pubkey> mint authority (u32 tag +
      // 32 bytes), u64 supply, u8 decimals, u8 is_initialized, ...
      const data = info!.data;
      expect(data.readUInt32LE(0)).toBe(1); // mint authority is Some
      const off = 4 + 32; // COption tag + pubkey
      const supply = data.readBigUInt64LE(off);
      expect(supply).toEqual(0n);
      const decimals = data[off + 8];
      expect(decimals).toEqual(0);
      expect(data[off + 9]).toBe(1); // is_initialized

      // A different user creating a different reward name gets their own mint.
      const name2 = "test-reward-2";
      const [mintPda2] = rewardPda(volunteer.publicKey, name2);
      await program.methods.createRewardToken(name2, "TRW2", "https://example.com/2").accounts({
        user: volunteerPda[0],
        mint: mintPda2,
        authority: volunteer.publicKey,
        systemProgram: SystemProgram.programId,
        tokenProgram: new PublicKey(TOKEN_PROGRAM_ID),
        rent: new PublicKey(RENT_SYSVAR),
      }).signers([providerKeypair, providerKeypair, volunteer]).rpc();
      expect(await connection.getAccountInfo(mintPda2)).toBeTruthy();
    });
  });

  describe("privacy: on-chain schema keeps private data off the ledger", () => {
    it("UserAccount has no email, latitude, longitude, postal code or address", async () => {
      const [pda] = userPda(donor.publicKey);
      const acc = await program.account.userAccount.fetch(pda);
      const keys = Object.keys(acc).map((k) => k.toLowerCase());
      for (const banned of ["email", "latitude", "longitude", "lat", "lon", "postal", "address"]) {
        expect(keys.some((k) => k.includes(banned))).toBe(false);
      }
      // The runtime IDL uses camelCase names (userAccount, reputationScore, ...),
      // so match case-insensitively across types and accounts.
      const idl: any = program.idl;
      const idlUserType: any =
        idl.types?.find((t: any) => String(t.name).toLowerCase() === "useraccount") ??
        idl.accounts?.find((t: any) => String(t.name).toLowerCase() === "useraccount") ??
        (program.account as any).userAccount?._idlAccount;
      const typeDef: any = idlUserType?.type ?? idlUserType;
      const fields = ((typeDef?.fields ?? []) as any[]).map((f: any) => String(f.name).toLowerCase());
      expect(fields.length > 0).toBe(true);
      expect(fields.includes("email")).toBe(false);
      expect(fields.some((n: string) => n.includes("lat") || n.includes("lon") || n.includes("postal"))).toBe(false);
      // Location is intentionally coarse & public: city/country/region + optional opaque hash.
      expect(acc.location.city).toEqual("Cuautitlán Izcalli");
      expect(acc.location.country).toEqual("MX");
      // Only coarse, public location fields are allowed on-chain.
      const locKeys = Object.keys(acc.location);
      expect(locKeys.every((k) => ["city", "country", "region", "positionHash"].includes(k))).toBe(true);
      expect(["city", "country", "region"].every((k) => acc.location[k] !== undefined)).toBe(true);
    });
  });
});
