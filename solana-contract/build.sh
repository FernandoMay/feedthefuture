#!/bin/bash

# Build script for Feed the Future Solana Contract
set -e

echo "🚀 Building Feed the Future Solana Contract..."

# Source cargo environment
source "$HOME/.cargo/env"

# Check if tools are installed
echo "📋 Checking tools..."
if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo not found. Please install Rust."
    exit 1
fi

if ! command -v solana &> /dev/null; then
    echo "❌ Solana CLI not found. Please install Solana CLI."
    exit 1
fi

echo "✅ Tools found!"

# Build the program
echo "🔨 Building program..."
cd programs/feed-the-future

cargo build-bpf --manifest-path=Cargo.toml --bpf-out-dir=../../target/deploy

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📦 Program built at: target/deploy/feed_the_future.so"
    
    # Show program info
    echo "📋 Program info:"
    ls -la ../../target/deploy/
    
    # Generate IDL
    echo "📚 Generating IDL..."
    cd ../..
    
    # Try to generate IDL with anchor if available
    if command -v anchor &> /dev/null; then
        anchor idl parse --file programs/feed-the-future/src/lib.rs
    else
        echo "⚠️  Anchor CLI not available for IDL generation"
    fi
    
    echo "🎉 Build complete!"
else
    echo "❌ Build failed!"
    exit 1
fi
