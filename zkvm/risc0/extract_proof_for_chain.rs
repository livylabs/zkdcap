// Extract zkVM proof data for on-chain verification
use risc0_zkvm::Receipt;
use std::fs;
use std::io::Write;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Extracting zkVM proof for on-chain verification...");
    
    // Read the full receipt
    let receipt_bytes = fs::read("quote_verification_receipt.bin")?;
    let receipt: Receipt = bincode::deserialize(&receipt_bytes)?;
    
    // Extract the seal (the actual zkVM proof)
    let seal = bincode::serialize(&receipt.inner)?;
    
    // Extract the journal (the public output)
    let journal = receipt.journal.bytes.clone();
    
    println!("Proof data extracted:");
    println!("   - Seal size: {} bytes", seal.len());
    println!("   - Journal size: {} bytes", journal.len());
    
    // Save seal as hex for easy copying
    let seal_hex = format!("0x{}", hex::encode(&seal));
    fs::write("seal_hex.txt", &seal_hex)?;
    println!("Seal (hex) saved to: seal_hex.txt");
    
    // Save journal as hex for easy copying
    let journal_hex = format!("0x{}", hex::encode(&journal));
    fs::write("journal_hex.txt", &journal_hex)?;
    println!("Journal (hex) saved to: journal_hex.txt");
    
    // Create a shell script for easy on-chain verification
    let contract_address = "0x4fa3ddCB722a7aA95f6409125dC60cC9CA5A4D16";
    let script_content = format!(
        "#!/bin/bash\n\
        echo \"Verifying zkVM proof on-chain...\"\n\
        echo \"Contract: {}\"\n\
        echo \"Seal: {}\"\n\
        echo \"Journal: {}\"\n\
        \n\
        cast send {} \"verifyQuote(bytes,bytes)\" \\\n\
            \"{}\" \\\n\
            \"{}\" \\\n\
            --private-key $PRIVATE_KEY \\\n\
            --rpc-url sepolia\n\
        \n\
        echo \"Verification transaction submitted!\"",
        contract_address,
        seal_hex,
        journal_hex,
        contract_address,
        seal_hex,
        journal_hex
    );
    
    fs::write("verify_on_chain.sh", script_content)?;
    println!("On-chain verification script saved to: verify_on_chain.sh");
    
    // Also create a simple test script
    let test_script = format!(
        "#!/bin/bash\n\
        echo \"Testing contract functions...\"\n\
        \n\
        # Test getImageId\n\
        echo \"Image ID:\"\n\
        cast call {} \"getImageId()\" --rpc-url sepolia\n\
        \n\
        # Test with mock data first\n\
        echo \"Testing with mock data...\"\n\
        cast send {} \"verifyQuote(bytes,bytes)\" \\\n\
            \"0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\" \\\n\
            \"0xdeadbeefcafebabe1234567890abcdef1234567890abcdef1234567890abcdef\" \\\n\
            --private-key $PRIVATE_KEY \\\n\
            --rpc-url sepolia\n\
        \n\
        echo \"Mock test completed!\"",
        contract_address,
        contract_address
    );
    
    fs::write("test_contract.sh", test_script)?;
    println!("Test script saved to: test_contract.sh");
    
    println!("\n✅ Proof extraction complete!");
    println!("📋 Files created:");
    println!("   - seal_hex.txt: The zkVM proof seal (hex format)");
    println!("   - journal_hex.txt: The verification result (hex format)");
    println!("   - verify_on_chain.sh: Script to verify on Sepolia");
    println!("   - test_contract.sh: Script to test contract functions");
    
    println!("\n🚀 To verify on-chain:");
    println!("   1. Make scripts executable: chmod +x *.sh");
    println!("   2. Set PRIVATE_KEY: export PRIVATE_KEY=your_key");
    println!("   3. Run: ./verify_on_chain.sh");
    
    Ok(())
}
