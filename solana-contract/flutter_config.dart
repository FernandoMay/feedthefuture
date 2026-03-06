// Flutter Configuration for Feed the Future Devnet
// Copy this to your Flutter app constants

class FeedTheFutureConfig {
  // Devnet Configuration
  static const String network = 'devnet';
  static const String rpcUrl = 'https://api.devnet.solana.com';
  static const String wsUrl = 'wss://api.devnet.solana.com';
  
  // Contract Configuration
  static const String programId = 'F1T3F11111111111111111111111111111111111111'; // Update after deploy
  
  // User Wallet (for testing)
  static const String testWalletAddress = '2epmpFanBWitW5bkYTW1Hd9EVZHPkPZihbaH6GRH3fuD';
  
  // Solana Explorer URLs
  static String getTransactionUrl(String signature) {
    return 'https://explorer.solana.com/tx/$signature?cluster=devnet';
  }
  
  static String getAccountUrl(String address) {
    return 'https://explorer.solana.com/address/$address?cluster=devnet';
  }
  
  static String getProgramUrl() {
    return 'https://explorer.solana.com/address/$programId?cluster=devnet';
  }
  
  // PDAs for testing
  static Future<String> getUserPDA(String userAddress) async {
    // This will be calculated in your Flutter app
    // Implementation depends on your Solana library
    return 'user_pda_placeholder';
  }
  
  static Future<String> getDonationPDA(String donorAddress, int timestamp) async {
    // This will be calculated in your Flutter app
    return 'donation_pda_placeholder';
  }
}

// Integration example for your Flutter app
class SolanaService {
  late final String rpcUrl;
  late final String programId;
  late final String userWallet;
  
  void initialize() {
    rpcUrl = FeedTheFutureConfig.rpcUrl;
    programId = FeedTheFutureConfig.programId;
    userWallet = FeedTheFutureConfig.testWalletAddress;
  }
  
  // Example: Initialize user
  Future<void> initializeUser({
    required String username,
    required String email,
    required Map<String, dynamic> location,
  }) async {
    // Implementation with your Solana library (solana, anchor, etc.)
    // This is a template - adapt to your specific library
    
    print('Initializing user: $username');
    print('Wallet: $userWallet');
    print('Program: $programId');
    print('Network: ${FeedTheFutureConfig.network}');
    
    // TODO: Implement actual Solana transaction
    // 1. Create user PDA
    // 2. Build transaction
    // 3. Sign with wallet
    // 4. Send transaction
    // 5. Handle response
  }
  
  // Example: Create donation
  Future<void> createDonation({
    required Map<String, dynamic> donationData,
  }) async {
    print('Creating donation with program: $programId');
    
    // TODO: Implement actual Solana transaction
  }
  
  // Example: Get user account
  Future<Map<String, dynamic>?> getUserAccount(String userAddress) async {
    print('Getting user account for: $userAddress');
    
    // TODO: Fetch account data from Solana
    return null;
  }
}
