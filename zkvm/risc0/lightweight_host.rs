// Lightweight host that generates actual zkVM proofs
use dcap_quote_verifier::types::quotes::Quote;
use dcap_pcs::client::PCSClient;
use base64::{Engine as _, engine::general_purpose};
use serde_json::Value;
use chrono::Utc;
use std::fs;

// RISC Zero imports
use risc0_zkvm::{default_prover, ExecutorEnv};

/// Prepare zkVM inputs by reading quote from JSON and fetching collateral from Intel PCS
pub fn prepare_zkvm_inputs_from_json(quote_json_path: &str) -> Result<(Vec<u8>, Vec<u8>, u64), Box<dyn std::error::Error>> {
    println!("Reading quote from: {}", quote_json_path);
    
    // 1. Read and parse the quote JSON
    let quote_data = fs::read_to_string(quote_json_path)?;
    let quote_json: Value = serde_json::from_str(&quote_data)?;
    
    // Extract the base64-encoded quote
    let quote_b64 = quote_json["tdx"]["quote"]
        .as_str()
        .ok_or("Missing 'tdx.quote' field in JSON")?;
    let quote_bytes = general_purpose::STANDARD.decode(quote_b64)?;

    println!("Quote decoded: {} bytes", quote_bytes.len());

    // 2. Parse the quote to extract QE cert data
    let (quote, _) = Quote::from_bytes(&quote_bytes)?;
    
    // 3. Extract QE cert data from the quote
    let qe_cert_data = match &quote {
        Quote::V3(quote_v3) => &quote_v3.signature.qe_cert_data,
        Quote::V4(quote_v4) => &quote_v4.signature.qe_cert_data,
    };

    // 4. Create PCS client and fetch collateral dynamically
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

    // 5. Get current time
    let current_time = Utc::now().timestamp() as u64;

    println!("Successfully prepared zkVM inputs:");
    println!("   - Quote bytes: {} bytes", quote_bytes.len());
    println!("   - Collateral bytes: {} bytes", collateral_bytes.len());
    println!("   - Current time: {}", current_time);

    Ok((quote_bytes, collateral_bytes, current_time))
}

/// Generate actual zkVM proof
pub fn generate_zkvm_proof() -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting zkVM proof generation...");
    
    // 1. Prepare the inputs
    let (quote_bytes, collateral_bytes, current_time) = 
        prepare_zkvm_inputs_from_json("livyquote/quote.json")?;
    
    // 2. Create the execution environment for the zkVM
    let env = ExecutorEnv::builder()
        .write(&(quote_bytes, collateral_bytes, current_time))? // ← Write as tuple
        .build()?;

    // 3. Load the guest program (the compiled zkVM binary)
    let guest_binary = include_bytes!("artifacts/dcap-quote-verifier");
    
    // 4. Execute the guest and generate the proof
    println!("Executing guest program in zkVM...");
    let prover = default_prover();
    let receipt = prover.prove(env, guest_binary)?;
    
    // 5. Extract the verification result from the receipt
    let result_bytes = receipt.receipt.journal.bytes.clone();
    
    println!("PROOF GENERATED SUCCESSFULLY!");
    println!("   - Receipt size: {} bytes", result_bytes.len());
    println!("   - Result bytes: {} bytes", result_bytes.len());
    
    // Try to decode as string, but don't fail if it's binary
    let result_str = String::from_utf8_lossy(&result_bytes);
    println!("   - Result (as string): {}", result_str);
    
    // 6. Save the proof to files
    let proof_path = "quote_verification_proof.bin";
    fs::write(proof_path, &receipt.receipt.journal.bytes)?;
    println!("Proof saved to: {}", proof_path);
    
    // Save the full receipt (contains the complete proof data)
    let receipt_path = "quote_verification_receipt.bin";
    let receipt_bytes = bincode::serialize(&receipt)?;
    fs::write(receipt_path, receipt_bytes)?;
    println!("Full receipt saved to: {}", receipt_path);
    
    // Save the verification result
    let result_path = "quote_verification_result.bin";
    fs::write(result_path, &result_bytes)?;
    println!("Verification result saved to: {}", result_path);
    
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("zkDCAP zkVM Proof Generator");
    println!("===========================");
    
    generate_zkvm_proof()?;
    
    println!("\nSUCCESS! zkVM proof generated for your TDX quote with Type 6 certificates!");
    Ok(())
}
