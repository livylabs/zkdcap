// verify_proof.rs - Verify the generated zkVM proof using RISC Zero
use risc0_zkvm::Receipt;
use std::fs;
use zkdcap_risc0::DCAP_QUOTE_VERIFIER_ID;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Verifying zkVM Proof with RISC Zero");
    println!("===================================");
    
    // 1. Load the receipt
    let receipt_path = "quote_verification_receipt.bin";
    println!("Loading receipt from: {}", receipt_path);
    
    let receipt_bytes = fs::read(receipt_path)?;
    println!("   - Receipt file size: {} bytes", receipt_bytes.len());
    
    // 2. Deserialize the receipt
    println!("Deserializing receipt...");
    let receipt: Receipt = bincode::deserialize(&receipt_bytes)?;
    println!("   - Receipt deserialized successfully");
    
    // 3. Verify the proof cryptographically
    println!("Verifying proof cryptographically...");
    receipt.verify(DCAP_QUOTE_VERIFIER_ID)?;
    
    println!("PROOF VERIFICATION SUCCESSFUL!");
    println!("   - The proof is cryptographically valid");
    println!("   - The computation was executed correctly");
    println!("   - The result is trustworthy");
    
    // 4. Show the verification result
    let result_bytes = receipt.journal.bytes.clone();
    println!("   - Result size: {} bytes", result_bytes.len());
    
    // Try to decode as string (it might be binary)
    let result_str = String::from_utf8_lossy(&result_bytes);
    println!("   - Result (as string): {}", result_str);
    
    // 5. Show proof metadata
    println!("\nProof Metadata:");
    println!("   - Receipt size: {} bytes", receipt_bytes.len());
    println!("   - Journal size: {} bytes", result_bytes.len());
    println!("   - Proof is valid and verifiable by anyone");
    
    Ok(())
}
