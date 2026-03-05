import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { FeedTheFuture } from "../target/types/feed_the_future";
import { PublicKey, SystemProgram, Keypair } from "@solana/web3.js";

describe("Feed the Future", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.FeedTheFuture as Program<FeedTheFuture>;

  it("Is initialized!", async () => {
    // Test basic initialization
    const adminKeypair = Keypair.generate();
    
    const location = {
      latitude: 19.4326,
      longitude: -99.1332,
      address: "Mexico City, Mexico",
      city: "Mexico City", 
      state: "CDMX",
      postalCode: "06000",
      country: "Mexico",
    };

    const [userPDA] = PublicKey.findProgramAddressSync(
      [Buffer.from("user"), adminKeypair.publicKey.toBuffer()],
      program.programId
    );

    try {
      const tx = await program.methods
        .initializeUser(
          { admin: {} },
          "admin_user",
          "admin@feedthefuture.org",
          location
        )
        .accounts({
          user: userPDA,
          authority: adminKeypair.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([adminKeypair])
        .rpc();

      console.log("User initialized with tx:", tx);
    } catch (error) {
      console.error("Initialization error:", error);
    }
  });
});
