use base64::{Engine as _, engine::general_purpose};
use dcap_quote_verifier::types::quotes::Quote;
use std::fs;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Read your quote
    let quote_data = fs::read_to_string("../livyquote/quote.json")?;
    let quote_json: serde_json::Value = serde_json::from_str(&quote_data)?;
    
    // Extract and decode the quote
    let quote_b64 = quote_json["tdx"]["quote"]
        .as_str()
        .ok_or("Missing 'tdx.quote' field in JSON")?;
    let quote_bytes = general_purpose::STANDARD.decode(quote_b64)?;
    
    // Parse the quote
    let (quote, _) = Quote::from_bytes(&quote_bytes)?;
    
    // Check the QE cert data type
    let qe_cert_data = match &quote {
        Quote::V3(quote_v3) => &quote_v3.signature.qe_cert_data,
        Quote::V4(quote_v4) => &quote_v4.signature.qe_cert_data,
    };
    
    println!("Your quote's QE Cert Type: {}", qe_cert_data.cert_data_type);
    println!("Cert data size: {} bytes", qe_cert_data.cert_data_size);
    
    // Determine quote type (SGX vs TDX)
    let is_sgx = match &quote {
        Quote::V3(quote_v3) => quote_v3.header.tee_type == 0x00000000,
        Quote::V4(quote_v4) => quote_v4.header.tee_type == 0x00000000,
    };
    
    println!("Quote type: {}", if is_sgx { "SGX" } else { "TDX" });
    
    match qe_cert_data.cert_data_type {
        0 => println!("Type 0: No certificate chain (not supported)"),
        1 => println!("Type 1: PPID in plain text (not supported)"),
        2 => println!("Type 2: PPID encrypted RSA-2048-OAEP (not supported)"),
        3 => println!("Type 3: PPID encrypted RSA-3072-OAEP (not supported)"),
        4 => println!("Type 4: PCK Leaf Certificate (not supported)"),
        5 => println!("Type 5: Full certificate chain (SUPPORTED!)"),
        6 => println!("Type 6: QE Report Certification Data (not supported)"),
        7 => println!("Type 7: Platform Manifest (not supported)"),
        _ => println!("Unknown type: {}", qe_cert_data.cert_data_type),
    }
    
    Ok(())
}
