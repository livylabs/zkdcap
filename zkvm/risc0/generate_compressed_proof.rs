use risc0_zkvm::{default_prover, ProverOpts};
use std::fs;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("=== GENERATING COMPRESSED PROOF ===");
    
    // Load the existing receipt
    println!("Loading existing receipt...");
    let receipt_bytes = fs::read("quote_verification_receipt.bin")?;
    let receipt: risc0_zkvm::Receipt = bincode::deserialize(&receipt_bytes)?;
    
    println!("Original receipt size: {} bytes", receipt_bytes.len());
    
    // Create prover with Succinct receipt kind (constant size, no Docker needed)
    let prover = default_prover();
    let opts = ProverOpts::succinct(); // This creates a Succinct receipt (constant size)
    
    println!("Compressing proof to Succinct format (constant size)...");
    println!("This may take several minutes - compression is computationally intensive...");
    
    // Compress the receipt
    let start_time = std::time::Instant::now();
    let compressed_receipt = prover.compress(&opts, &receipt)?;
    let compression_time = start_time.elapsed();
    
    println!("Compression completed in {:.2} seconds", compression_time.as_secs_f64());
    
    // Serialize the compressed receipt
    let compressed_bytes = bincode::serialize(&compressed_receipt)?;
    
    println!("Compressed receipt size: {} bytes", compressed_bytes.len());
    println!("Compression ratio: {:.2}x", receipt_bytes.len() as f64 / compressed_bytes.len() as f64);
    
    // Save the compressed receipt
    fs::write("quote_verification_receipt_compressed.bin", &compressed_bytes)?;
    
    // Verify the compressed receipt
    println!("Verifying compressed receipt...");
    compressed_receipt.verify(zkdcap_risc0::DCAP_QUOTE_VERIFIER_ID)?;
    
    println!("✅ Compressed proof generated and verified successfully!");
    println!("   - Original size: {} bytes", receipt_bytes.len());
    println!("   - Compressed size: {} bytes", compressed_bytes.len());
    println!("   - Compression ratio: {:.2}x", receipt_bytes.len() as f64 / compressed_bytes.len() as f64);
    
    // Extract hex data for on-chain verification
    let seal_bytes = bincode::serialize(&compressed_receipt.inner)?;
    let journal_bytes = compressed_receipt.journal.bytes.clone();
    
    let seal_hex = format!("0x{}", hex::encode(&seal_bytes));
    let journal_hex = format!("0x{}", hex::encode(&journal_bytes));
    
    fs::write("seal_compressed_hex.txt", seal_hex)?;
    fs::write("journal_compressed_hex.txt", journal_hex)?;
    
    println!("Compressed proof data saved:");
    println!("   - seal_compressed_hex.txt: {} chars", fs::read_to_string("seal_compressed_hex.txt")?.len());
    println!("   - journal_compressed_hex.txt: {} chars", fs::read_to_string("journal_compressed_hex.txt")?.len());
    
    Ok(())
}
