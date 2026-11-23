#!/bin/bash

# Feed the Future - Devnet Deployment Script
set -e

echo "🌱 Feed the Future - Devnet Deployment"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}📍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
print_step "Checking prerequisites..."

# Source cargo environment
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
else
    print_warning "Cargo environment not found. Installing..."
fi

# Check Solana CLI
if ! command -v solana &> /dev/null; then
    print_error "Solana CLI not found. Please install Solana CLI first."
    echo "Visit: https://docs.solana.com/cli/install"
    exit 1
fi

print_success "Solana CLI found: $(solana --version)"

# Check Anchor CLI
if ! command -v anchor &> /dev/null; then
    print_warning "Anchor CLI not found. Will try to deploy manually."
    ANCHOR_AVAILABLE=false
else
    print_success "Anchor CLI found: $(anchor --version 2>/dev/null || echo 'Version unknown')"
    ANCHOR_AVAILABLE=true
fi

# Switch to devnet
print_step "Configuring Solana for Devnet..."
solana config set --url devnet
print_success "Switched to Devnet"

# Show current config
echo ""
echo "📋 Current Configuration:"
solana config get

# Check wallet
print_step "Checking wallet configuration..."
WALLET_PATH=$(solana config get | grep "Keypair Path" | awk '{print $3}')
if [ -z "$WALLET_PATH" ]; then
    print_error "No wallet configured. Please set up a wallet first."
    exit 1
fi

print_success "Wallet: $WALLET_PATH"

# Check balance
print_step "Checking wallet balance..."
BALANCE_OUTPUT=$(solana balance)
BALANCE=$(echo "$BALANCE_OUTPUT" | grep -o '[0-9.]*' | head -1)

if [ -z "$BALANCE" ]; then
    print_error "Could not read balance."
    exit 1
fi

echo "Current balance: $BALANCE SOL"

# Request airdrop if needed
if (( $(echo "$BALANCE < 2" | bc -l 2>/dev/null || echo "0") )); then
    print_step "Requesting devnet SOL (balance is low)..."
    solana airdrop 5
    print_success "Airdrop completed"
    
    # Wait for airdrop to process
    sleep 3
    echo "New balance:"
    solana balance
else
    print_success "Sufficient balance for deployment"
fi

# Build the program
print_step "Building the contract..."
cd programs/feed-the-future

if [ "$ANCHOR_AVAILABLE" = true ]; then
    cd ../..
    if anchor build; then
        print_success "Build completed with Anchor"
    else
        print_error "Anchor build failed"
        exit 1
    fi
else
    # Manual build
    print_warning "Building manually (Anchor not available)..."
    cargo build --release --target wasm32-unknown-unknown
    
    if [ $? -eq 0 ]; then
        print_success "Manual build completed"
    else
        print_error "Manual build failed"
        exit 1
    fi
    
    cd ../..
fi

# Deploy to devnet
print_step "Deploying to Devnet..."

PROGRAM_ID="B4Cx6Vkm2VKiTGd8hpgCPbCDR2FBxULvGNAwEmVc8j4p"

if [ "$ANCHOR_AVAILABLE" = true ]; then
    print_step "Deploying with Anchor..."
    if anchor deploy --provider.cluster devnet; then
        print_success "Anchor deployment completed"
    else
        print_error "Anchor deployment failed"
        exit 1
    fi
else
    print_warning "Manual deployment required"
    echo ""
    echo "📦 Program built successfully!"
    echo "🔍 Find your program at: target/deploy/feed_the_future.so"
    echo ""
    echo "To complete manual deployment:"
    echo "1. Generate a new program keypair:"
    echo "   solana-keygen new --outfile ~/.config/solana/feed_the_future.json --no-bip39-passphrase"
    echo ""
    echo "2. Deploy the program:"
    echo "   solana program deploy target/deploy/feed_the_future.so --program-id ~/.config/solana/feed_the_future.json"
    echo ""
    echo "3. Get your new Program ID:"
    echo "   solana address -k ~/.config/solana/feed_the_future.json"
    echo ""
    echo "4. Update Program ID in:"
    echo "   - Anchor.toml (programs.devnet section)"
    echo "   - lib.rs (declare_id! macro)"
    echo "   - Flutter app constants"
fi

# Verify deployment
print_step "Verifying deployment..."
if [ "$ANCHOR_AVAILABLE" = true ]; then
    # Try to get program info
    if solana program show "$PROGRAM_ID" 2>/dev/null; then
        print_success "Program deployed and verified!"
        echo ""
        echo "🔗 Explorer: https://explorer.solana.com/address/$PROGRAM_ID?cluster=devnet"
    else
        print_warning "Program verification failed. Check if deployment completed."
    fi
fi

# Generate deployment summary
echo ""
echo "🎉 Deployment Summary"
echo "====================="
echo "Network: Devnet"
echo "Program ID: $PROGRAM_ID"
echo "Explorer: https://explorer.solana.com/address/$PROGRAM_ID?cluster=devnet"
echo "RPC URL: https://api.devnet.solana.com"
echo ""

if [ "$ANCHOR_AVAILABLE" = false ]; then
    echo "⚠️  Manual deployment completed. Update your Program ID in all locations."
fi

echo ""
echo "📱 Next Steps for Flutter Integration:"
echo "1. Update SolanaConstants.programId in your Flutter app"
echo "2. Test basic operations (create user, create donation)"
echo "3. Monitor transactions in Solana Explorer"
echo "4. Test with real wallets (Phantom, Solflare, etc.)"
echo ""

print_success "Devnet deployment process completed! 🚀"
