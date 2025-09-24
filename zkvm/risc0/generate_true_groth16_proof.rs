use risc0_zkvm::{default_prover, ProverOpts, ExecutorEnv, Receipt};
use std::fs;
use zkdcap_risc0::DCAP_QUOTE_VERIFIER_ID;
use dcap_quote_verifier::types::quotes::Quote;
use dcap_pcs::client::PCSClient;
use base64::{Engine as _, engine::general_purpose};
use serde_json::Value;
use chrono::Utc;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Set memory optimization environment variables
    std::env::set_var("RUST_LOG", "info");
    // std::env::set_var("RISC0_DEV_MODE", "1"); // Commented out - we need real proofs
    
    println!("=== GENERATING TRUE GROTH16 PROOF FROM SCRATCH ===");
    
    // 1. Prepare the inputs (copying from lightweight_host.rs but for Groth16)
    println!("Preparing zkVM inputs...");
    
    // Read and parse the quote JSON
    let quote_data = fs::read_to_string("livyquote/quote.json")?;
    let quote_json: Value = serde_json::from_str(&quote_data)?;
    
    // Extract the base64-encoded quote
    let quote_b64 = quote_json["tdx"]["quote"]
        .as_str()
        .ok_or("Missing 'tdx.quote' field in JSON")?;
    let quote_bytes = general_purpose::STANDARD.decode(quote_b64)?;

    println!("Quote decoded: {} bytes", quote_bytes.len());

    // Parse the quote to extract QE cert data
    let (quote, _) = Quote::from_bytes(&quote_bytes)?;
    
    // Extract QE cert data from the quote
    let qe_cert_data = match &quote {
        Quote::V3(quote_v3) => &quote_v3.signature.qe_cert_data,
        Quote::V4(quote_v4) => &quote_v4.signature.qe_cert_data,
    };

    // Create PCS client and fetch collateral dynamically
    let pcs_client = PCSClient::default();
    
    // Determine if it's SGX or TDX based on quote
    let is_sgx = match &quote {
        Quote::V3(quote_v3) => quote_v3.header.tee_type == 0x00000000, // SGX
        Quote::V4(quote_v4) => quote_v4.header.tee_type == 0x00000000, // SGX
    };
    
    println!("Quote type: {}", if is_sgx { "SGX" } else { "TDX" });
    println!("QE Cert Type: {}", qe_cert_data.cert_data_type);
    println!("Fetching collateral from Intel PCS...");
    
    // Fetch collateral from Intel PCS
    let collateral = pcs_client.get_collateral(is_sgx, qe_cert_data)?;
    let collateral_bytes = collateral.to_bytes();

    // Get current time
    let current_time = Utc::now().timestamp() as u64;
    
    println!("Successfully prepared zkVM inputs:");
    println!("   - Quote bytes: {} bytes", quote_bytes.len());
    println!("   - Collateral bytes: {} bytes", collateral_bytes.len());
    println!("   - Current time: {}", current_time);
    
    // 2. Create the execution environment for the zkVM
    let env = ExecutorEnv::builder()
        .write(&(quote_bytes, collateral_bytes, current_time))?
        .build()?;

    // 3. Load the guest program (the compiled zkVM binary)
    let guest_binary = include_bytes!("target/riscv-guest/zkdcap-risc0/guests/riscv32im-risc0-zkvm-elf/release/dcap_quote_verifier");
    
    // 4. Create prover with Groth16 receipt kind (TRUE Groth16 from start)
    println!("Creating prover with Groth16 receipt kind...");
    let prover = default_prover();
    let opts = ProverOpts::groth16(); // This will generate a TRUE Groth16 receipt
    
    // 5. Execute the guest and generate the TRUE Groth16 proof
    println!("Executing guest program in zkVM with Groth16 proving...");
    println!("This will take several minutes - Groth16 proving is computationally intensive...");
    
    let start_time = std::time::Instant::now();
    let groth16_receipt = prover.prove_with_opts(env, guest_binary, &opts)?;
    let proving_time = start_time.elapsed();
    
    println!("Groth16 proof generation completed in {:.2} seconds", proving_time.as_secs_f64());
    
    // 6. Verify the Groth16 receipt
    println!("Verifying Groth16 receipt...");
    groth16_receipt.receipt.verify(DCAP_QUOTE_VERIFIER_ID)?;
    println!("✅ Groth16 receipt verification successful!");
    
    // 7. Save the Groth16 receipt (this is all we need)
    let receipt_path = "groth16_receipt.bin";
    let receipt_bytes = bincode::serialize(&groth16_receipt.receipt)?;
    fs::write(receipt_path, &receipt_bytes)?;
    println!("Groth16 receipt saved to: {}", receipt_path);
    
    // Debug: Print receipt structure information
    println!("\n=== RECEIPT STRUCTURE DEBUG ===");
    println!("Receipt type: {:?}", std::any::type_name_of_val(&groth16_receipt.receipt));
    println!("Seal length: {} bytes", groth16_receipt.receipt.seal.len());
    println!("Image ID: {:?}", groth16_receipt.receipt.claim.image_id);
    println!("Exit code: {:?}", groth16_receipt.receipt.claim.exit_code);
    
    // The journal is in the claim, not directly in the receipt
    // Let's see what's in the claim
    println!("Claim type: {:?}", std::any::type_name_of_val(&groth16_receipt.receipt.claim));
    
    // Print seal preview (first 50 bytes)
    let seal_preview = &groth16_receipt.receipt.seal[..std::cmp::min(50, groth16_receipt.receipt.seal.len())];
    println!("Seal preview (first 50 bytes): {:?}", seal_preview);
    
    // 8. Extract components for on-chain verification
    println!("\n=== EXTRACTING COMPONENTS FOR ON-CHAIN VERIFICATION ===");
    
    // Extract the seal (Groth16 proof)
    let seal_bytes = bincode::serialize(&groth16_receipt.receipt.inner)?;
    let journal_bytes = groth16_receipt.receipt.journal.bytes.clone();
    
    let seal_hex = format!("0x{}", hex::encode(&seal_bytes));
    let journal_hex = format!("0x{}", hex::encode(&journal_bytes));
    
    fs::write("groth16_seal_hex.txt", seal_hex)?;
    fs::write("groth16_journal_hex.txt", journal_hex)?;
    
    println!("Groth16 components saved:");
    println!("   - groth16_seal_hex.txt: {} chars", fs::read_to_string("groth16_seal_hex.txt")?.len());
    println!("   - groth16_journal_hex.txt: {} chars", fs::read_to_string("groth16_journal_hex.txt")?.len());
    
    println!("\n🎉 Groth16 receipt generated successfully!");
    println!("📋 Files created:");
    println!("   - groth16_receipt.bin: Full Groth16 receipt");
    println!("   - groth16_seal_hex.txt: Groth16 proof seal");
    println!("   - groth16_journal_hex.txt: Journal data");
    
    Ok(())
}
