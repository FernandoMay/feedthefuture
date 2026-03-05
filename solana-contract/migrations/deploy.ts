import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { FeedTheFuture } from "../target/types/feed_the_future";
import { 
  PublicKey,
  SystemProgram,
  Keypair,
  Connection,
  LAMPORTS_PER_SOL
} from "@solana/web3.js";
import { 
  TOKEN_PROGRAM_ID,
  createInitializeMint2Instruction,
  getAssociatedTokenAddress,
  createAssociatedTokenAccountInstruction
} from "@solana/spl-token";
import { 
  createInitializeMetadataPointerInstruction,
  createSetAuthorityInstruction,
  AuthorityType
} from "@solana/spl-token-metadata";

describe("Feed the Future - Deployment", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.FeedTheFuture as Program<FeedTheFuture>;
  const connection = provider.connection;

  // Test accounts
  let adminKeypair: Keypair;
  let donorKeypair: Keypair;
  let ngoKeypair: Keypair;
  let volunteerKeypair: Keypair;

  // PDAs
  let globalConfigPDA: PublicKey;
  let adminUserPDA: PublicKey;
  let donorUserPDA: PublicKey;
  let ngoUserPDA: PublicKey;
  let volunteerUserPDA: PublicKey;

  before(async () => {
    // Generate test keypairs
    adminKeypair = Keypair.generate();
    donorKeypair = Keypair.generate();
    ngoKeypair = Keypair.generate();
    volunteerKeypair = Keypair.generate();

    // Fund test accounts
    await connection.requestAirdrop(adminKeypair.publicKey, 10 * LAMPORTS_PER_SOL);
    await connection.requestAirdrop(donorKeypair.publicKey, 10 * LAMPORTS_PER_SOL);
    await connection.requestAirdrop(ngoKeypair.publicKey, 10 * LAMPORTS_PER_SOL);
    await connection.requestAirdrop(volunteerKeypair.publicKey, 10 * LAMPORTS_PER_SOL);

    // Wait for funding
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Find PDAs
    [globalConfigPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("config")],
      program.programId
    );

    [adminUserPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("user"), adminKeypair.publicKey.toBuffer()],
      program.programId
    );

    [donorUserPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("user"), donorKeypair.publicKey.toBuffer()],
      program.programId
    );

    [ngoUserPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("user"), ngoKeypair.publicKey.toBuffer()],
      program.programId
    );

    [volunteerUserPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("user"), volunteerKeypair.publicKey.toBuffer()],
      program.programId
    );
  });

  it("Initializes global configuration", async () => {
    const config = {
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

    const tx = await program.methods
      .initializeConfig(config)
      .accounts({
        globalConfig: globalConfigPDA,
        authority: adminKeypair.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .signers([adminKeypair])
      .rpc();

    console.log("Global config initialized with tx:", tx);

    // Verify config
    const configAccount = await program.account.globalConfigAccount.fetch(globalConfigPDA);
    console.log("Config authority:", configAccount.authority.toString());
    console.log("Min reputation for matching:", configAccount.config.minReputationForMatching);
  });

  it("Creates admin user", async () => {
    const location = {
      latitude: 19.4326,
      longitude: -99.1332,
      address: "Mexico City, Mexico",
      city: "Mexico City",
      state: "CDMX",
      postalCode: "06000",
      country: "Mexico",
    };

    const tx = await program.methods
      .initializeUser(
        { admin: {} },
        "admin_user",
        "admin@feedthefuture.org",
        location
      )
      .accounts({
        user: adminUserPDA,
        authority: adminKeypair.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .signers([adminKeypair])
      .rpc();

    console.log("Admin user created with tx:", tx);

    // Verify user
    const userAccount = await program.account.userAccount.fetch(adminUserPDA);
    console.log("Admin user role:", userAccount.role);
    console.log("Admin reputation:", userAccount.reputationScore);
  });

  it("Creates donor user", async () => {
    const location = {
      latitude: 19.4326,
      longitude: -99.1332,
      address: "Restaurant Street 123, Mexico City",
      city: "Mexico City",
      state: "CDMX",
      postalCode: "06010",
      country: "Mexico",
    };

    const tx = await program.methods
      .initializeUser(
        { donor: {} },
        "restaurant_donor",
        "donor@restaurant.com",
        location
      )
      .accounts({
        user: donorUserPDA,
        authority: donorKeypair.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .signers([donorKeypair])
      .rpc();

    console.log("Donor user created with tx:", tx);
  });

  it("Creates NGO user", async () => {
    const location = {
      latitude: 19.4326,
      longitude: -99.1332,
      address: "Charity Avenue 456, Mexico City",
      city: "Mexico City",
      state: "CDMX",
      postalCode: "06020",
      country: "Mexico",
    };

    const tx = await program.methods
      .initializeUser(
        { ngo: {} },
        "helping_hands_ngo",
        "ngo@helpinghands.org",
        location
      )
      .accounts({
        user: ngoUserPDA,
        authority: ngoKeypair.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .signers([ngoKeypair])
      .rpc();

    console.log("NGO user created with tx:", tx);
  });

  it("Creates volunteer user", async () => {
    const location = {
      latitude: 19.4326,
      longitude: -99.1332,
      address: "Volunteer Street 789, Mexico City",
      city: "Mexico City",
      state: "CDMX",
      postalCode: "06030",
      country: "Mexico",
    };

    const tx = await program.methods
      .initializeUser(
        { volunteer: {} },
        "delivery_hero",
        "volunteer@hero.org",
        location
      )
      .accounts({
        user: volunteerUserPDA,
        authority: volunteerKeypair.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .signers([volunteerKeypair])
      .rpc();

    console.log("Volunteer user created with tx:", tx);
  });

  it("Verifies NGO user", async () => {
    const tx = await program.methods
      .verifyUser()
      .accounts({
        user: ngoUserPDA,
        authorityUser: adminUserPDA,
        authority: adminKeypair.publicKey,
      })
      .signers([adminKeypair])
      .rpc();

    console.log("NGO user verified with tx:", tx);

    // Verify verification
    const ngoAccount = await program.account.userAccount.fetch(ngoUserPDA);
    console.log("NGO is verified:", ngoAccount.isVerified);
  });

  it("Creates a donation", async () => {
    const donationData = {
      name: "Fresh Vegetables",
      category: "Frutas y Verduras",
      quantity: 50,
      unit: "kg",
      description: "Mixed fresh vegetables including tomatoes, lettuce, and carrots",
      expirationDate: "2024-12-15",
      storageRequirements: "Keep refrigerated at 4°C",
      isUrgent: true,
      isPerishable: true,
      requiresRefrigeration: true,
      images: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
    };

    const [donationPDA] = PublicKey.findProgramAddressSync(
      [
        Buffer.from("donation"),
        donorKeypair.publicKey.toBuffer(),
        Buffer.from(new Date().getTime().toString())
      ],
      program.programId
    );

    const tx = await program.methods
      .createDonation(donationData)
      .accounts({
        donation: donationPDA,
        donorAccount: donorUserPDA,
        donor: donorKeypair.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .signers([donorKeypair])
      .rpc();

    console.log("Donation created with tx:", tx);

    // Verify donation
    const donationAccount = await program.account.donation.fetch(donationPDA);
    console.log("Donation status:", donationAccount.status);
    console.log("Donation quantity:", donationAccount.donationData.quantity);
    console.log("Is urgent:", donationAccount.donationData.isUrgent);
  });

  it("Matches donation with NGO", async () => {
    // For this test, we'll use a known donation PDA
    // In production, you would get this from the previous step
    const [donationPDA] = PublicKey.findProgramAddressSync(
      [
        Buffer.from("donation"),
        donorKeypair.publicKey.toBuffer(),
        Buffer.from(new Date().getTime().toString())
      ],
      program.programId
    );

    const tx = await program.methods
      .matchDonation(ngoUserPDA)
      .accounts({
        donation: donationPDA,
        ngoUser: ngoUserPDA,
        ngo: ngoKeypair.publicKey,
      })
      .signers([ngoKeypair])
      .rpc();

    console.log("Donation matched with tx:", tx);
  });

  it("Updates user reputation", async () => {
    const tx = await program.methods
      .updateReputation(
        donorKeypair.publicKey,
        10, // +10 reputation points
        "Successful donation completion"
      )
      .accounts({
        targetUserAccount: donorUserPDA,
        authorityUser: adminUserPDA,
        authority: adminKeypair.publicKey,
      })
      .signers([adminKeypair])
      .rpc();

    console.log("Reputation updated with tx:", tx);

    // Verify reputation
    const donorAccount = await program.account.userAccount.fetch(donorUserPDA);
    console.log("New reputation score:", donorAccount.reputationScore);
  });

  after(async () => {
    console.log("\n=== Deployment Summary ===");
    console.log("Program ID:", program.programId.toString());
    console.log("Global Config PDA:", globalConfigPDA.toString());
    console.log("Admin User PDA:", adminUserPDA.toString());
    console.log("Donor User PDA:", donorUserPDA.toString());
    console.log("NGO User PDA:", ngoUserPDA.toString());
    console.log("Volunteer User PDA:", volunteerUserPDA.toString());
    console.log("\nContract deployed successfully! 🚀");
  });
});
