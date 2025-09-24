use risc0_zkvm::Receipt;
use std::fs;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Read the binary receipt file
    let receipt_path = "groth16_receipt.bin";
    let receipt_bytes = fs::read(receipt_path)?;
    
    // Deserialize the receipt
    let receipt: Receipt = bincode::deserialize(&receipt_bytes)?;
    
    // Get the claim
    let claim = receipt.claim()?;
    
    match claim {
        risc0_zkvm::MaybePruned::Value(ref claim_data) => {
            match &claim_data.pre {
                risc0_zkvm::MaybePruned::Value(pre_state) => {
                    let image_id_hex = format!("0x{}", hex::encode(pre_state.merkle_root.as_bytes()));
                    println!("Current Image ID from proof: {}", image_id_hex);
                }
                risc0_zkvm::MaybePruned::Pruned(digest) => {
                    let image_id_hex = format!("0x{}", hex::encode(digest.as_bytes()));
                    println!("Current Image ID from proof: {}", image_id_hex);
                }
            }
        }
        risc0_zkvm::MaybePruned::Pruned(_) => {
            println!("Claim is pruned, cannot access image ID");
        }
    }
    
    Ok(())
}
