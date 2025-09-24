use risc0_zkvm::Receipt;
use risc0_zkvm::sha::rust_crypto::{Sha256, Digest};
use std::fs;
use bincode;
use hex;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("=== EXTRACTING DATA FROM GROTH16 RECEIPT BIN ===");
    
    // 1. Read the binary receipt file
    let receipt_path = "groth16_receipt.bin";
    let receipt_bytes = fs::read(receipt_path)?;
    println!("Read {} bytes from {}", receipt_bytes.len(), receipt_path);
    
    // 2. Deserialize the receipt - it's a regular Receipt with Groth16 inner receipt
    let receipt: Receipt = bincode::deserialize(&receipt_bytes)?;
    println!("✅ Successfully deserialized receipt");
    
    // 3. Extract the seal from the inner receipt (Groth16 proof)
    // The inner receipt is an enum, we need to match on Groth16 variant
    let seal_bytes = match &receipt.inner {
        risc0_zkvm::InnerReceipt::Groth16(groth16_receipt) => &groth16_receipt.seal,
        _ => {
            println!("Error: Expected Groth16 receipt, got different inner receipt type");
            return Err("Not a Groth16 receipt".into());
        }
    };
    let seal_hex = format!("0x{}", hex::encode(seal_bytes));
    println!("Seal length: {} bytes", seal_bytes.len());
    
    // 4. Extract the journal data - this is the actual journal bytes!
    let journal_bytes = &receipt.journal.bytes;
    let journal_hex = format!("0x{}", hex::encode(journal_bytes));
    println!("Journal length: {} bytes", journal_bytes.len());
    
    // 5. Calculate journal digest for on-chain verification (SHA-256 as required by RISC Zero)
    let journal_digest = Sha256::digest(journal_bytes);
    let journal_digest_hex = format!("0x{}", hex::encode(journal_digest));
    println!("Journal digest (SHA256): {}", journal_digest_hex);
    
        // 6. Extract claim information for debugging
        let claim = receipt.claim()?;
        match claim {
            risc0_zkvm::MaybePruned::Pruned(_) => {
                println!("Claim is pruned, cannot access fields");
            }
            risc0_zkvm::MaybePruned::Value(ref claim_data) => {
                println!("Pre state: {:?}", claim_data.pre);
                println!("Post state: {:?}", claim_data.post);
                println!("Exit code: {:?}", claim_data.exit_code);
                println!("Input: {:?}", claim_data.input);
                println!("Output: {:?}", claim_data.output);
                
                // Extract the actual image ID from the pre state
                match &claim_data.pre {
                    risc0_zkvm::MaybePruned::Value(pre_state) => {
                        let image_id_hex = format!("0x{}", hex::encode(pre_state.merkle_root.as_bytes()));
                        println!("=== ACTUAL IMAGE ID FROM PROOF ===");
                        println!("Image ID: {}", image_id_hex);
                        fs::write("extracted_image_id.txt", &image_id_hex)?;
                    }
                    risc0_zkvm::MaybePruned::Pruned(digest) => {
                        let image_id_hex = format!("0x{}", hex::encode(digest.as_bytes()));
                        println!("=== ACTUAL IMAGE ID FROM PROOF ===");
                        println!("Image ID: {}", image_id_hex);
                        fs::write("extracted_image_id.txt", &image_id_hex)?;
                    }
                }
            
            // Extract post state digest - need to handle MaybePruned wrapper
            match &claim_data.post {
                risc0_zkvm::MaybePruned::Value(post_state) => {
                    let post_state_bytes = bincode::serialize(post_state)?;
                    let post_state_hex = format!("0x{}", hex::encode(&post_state_bytes));
                    println!("Post state digest: {}", post_state_hex);
                    fs::write("extracted_post_state_digest.txt", &post_state_hex)?;
                }
                risc0_zkvm::MaybePruned::Pruned(digest) => {
                    let post_state_hex = format!("0x{}", hex::encode(digest.as_bytes()));
                    println!("Post state digest (pruned): {}", post_state_hex);
                    fs::write("extracted_post_state_digest.txt", &post_state_hex)?;
                }
            }
        }
    }
    
    // 7. Save all the extracted data
    fs::write("extracted_seal_hex.txt", &seal_hex)?;
    fs::write("extracted_journal_hex.txt", &journal_hex)?;
    fs::write("extracted_journal_digest.txt", &journal_digest_hex)?;
    
    println!("\n=== EXTRACTED DATA SAVED ===");
    println!("✅ extracted_seal_hex.txt: {} chars", seal_hex.len());
    println!("✅ extracted_journal_hex.txt: {} chars", journal_hex.len());
    println!("✅ extracted_journal_digest.txt: {} chars", journal_digest_hex.len());
    
    // 8. Print the data for verification
    println!("\n=== EXTRACTED DATA ===");
    println!("Seal (first 100 chars): {}", &seal_hex[..std::cmp::min(100, seal_hex.len())]);
    println!("Journal (first 100 chars): {}", &journal_hex[..std::cmp::min(100, journal_hex.len())]);
    println!("Journal Digest: {}", journal_digest_hex);
    match claim {
        risc0_zkvm::MaybePruned::Value(ref claim_data) => {
            println!("Pre state: {:?}", claim_data.pre);
        }
        risc0_zkvm::MaybePruned::Pruned(_) => {
            println!("Claim is pruned, cannot access pre state");
        }
    }
    
    println!("\nExtraction complete! Use these values for on-chain verification.");
    
    Ok(())
}
