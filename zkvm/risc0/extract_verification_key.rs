use risc0_zkvm::{Receipt, sha::Digestible};
use std::fs;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("=== EXTRACTING VERIFICATION KEY FROM PROOF ===");
    
    // Load the original receipt
    let receipt_bytes = fs::read("quote_verification_receipt.bin")?;
    let receipt: Receipt = bincode::deserialize(&receipt_bytes)?;
    
    println!("Receipt type: {:?}", receipt.inner);
    
    // Try to extract Groth16 information
    if let Ok(groth16_receipt) = receipt.inner.groth16() {
        println!("Found Groth16 receipt!");
        println!("Seal length: {} bytes", groth16_receipt.seal.len());
        
        // The seal contains the proof and verification key information
        let seal = &groth16_receipt.seal;
        
        // Print first few bytes to understand the format
        println!("First 32 bytes of seal: {}", hex::encode(&seal[..32.min(seal.len())]));
        
        // Try to extract verification key parameters
        // The Groth16 proof format typically includes the verification key
        println!("Total seal size: {} bytes", seal.len());
        
        // Look for patterns that might be verification key constants
        if seal.len() > 1000 {
            println!("This looks like a full Groth16 proof with embedded verification key");
            
            // The verification key is typically embedded in the proof
            // Let's try to extract it by looking at the structure
            println!("Attempting to extract verification key parameters...");
            
            // For now, let's just print the structure
            println!("Seal structure analysis:");
            println!("  - First 4 bytes (selector): {}", hex::encode(&seal[..4]));
            println!("  - Next 64 bytes (A): {}", hex::encode(&seal[4..68]));
            println!("  - Next 128 bytes (B): {}", hex::encode(&seal[68..196]));
            println!("  - Next 64 bytes (C): {}", hex::encode(&seal[196..260]));
            
            if seal.len() > 260 {
                println!("  - Remaining {} bytes (public signals + verification key)", seal.len() - 260);
            }
        }
    } else {
        println!("This is not a Groth16 receipt");
        println!("Receipt type: {:?}", receipt.inner);
    }
    
    // Also try to get the verifier parameters digest
    let verifier_params = risc0_zkvm::Groth16ReceiptVerifierParameters::default();
    let verifier_digest = verifier_params.digest();
    println!("\nVerifier parameters digest: {}", hex::encode(verifier_digest.as_bytes()));
    println!("Selector (first 4 bytes): {}", hex::encode(&verifier_digest.as_bytes()[..4]));
    
    Ok(())
}
