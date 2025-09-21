use dcap_quote_verifier::collateral::QvCollateral;
use dcap_quote_verifier::types::quotes::Quote;
use dcap_quote_verifier::quotes::verify_quote;
use risc0_zkvm::guest::env;

fn main() {
    // Read inputs from zkVM environment using the correct approach
    let input_data: (Vec<u8>, Vec<u8>, u64) = env::read();

    let (quote_bytes, collateral_bytes, current_time) = input_data;

    // Log memory usage for debugging
    env::log(&format!("Quote size: {} bytes", quote_bytes.len()));
    env::log(&format!("Collateral size: {} bytes", collateral_bytes.len()));
    env::log(&format!("Current time: {}", current_time));

    // Parse the quote with better error handling
    let (quote, _) = match Quote::from_bytes(&quote_bytes) {
        Ok(result) => {
            env::log("Quote parsed successfully");
            result
        },
        Err(e) => {
            env::log(&format!("Quote parsing failed: {}", e));
            panic!("Quote parsing failed: {}", e);
        }
    };
    
    // Parse the collateral with better error handling
    let collateral = match QvCollateral::from_bytes(&collateral_bytes) {
        Ok(result) => {
            env::log("Collateral parsed successfully");
            result
        },
        Err(e) => {
            env::log(&format!("Collateral parsing failed: {}", e));
            panic!("Collateral parsing failed: {}", e);
        }
    };

    // Verify the quote with better error handling
    env::log("Starting quote verification...");
    let result = match verify_quote(&quote, &collateral, current_time) {
        Ok(result) => {
            env::log("Quote verification successful");
            result
        },
        Err(e) => {
            env::log(&format!("Quote verification failed: {}", e));
            panic!("Quote verification failed: {}", e);
        }
    };
    
    // Commit the result
    env::log("Committing result...");
    env::commit_slice(result.to_bytes().as_slice());
    env::log("Result committed successfully");
}


