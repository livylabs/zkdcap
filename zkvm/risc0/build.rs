use risc0_binfmt::ProgramBinary;
use risc0_build::{embed_method_metadata_with_options, GuestOptionsBuilder};
use std::{collections::HashMap, env, fs::File, io::Write};

fn main() {
    println!("cargo:rerun-if-env-changed=ZKDCAP_RISC0_BUILD");
    match env::var("ZKDCAP_RISC0_BUILD") {
        Ok(v) if v == "1" => {
            println!("debug: ZKDCAP_RISC0_BUILD is set");
        }
        _ => {
            println!("debug: ZKDCAP_RISC0_BUILD is not set");
            return;
        }
    }

    // Use native compilation on your metal CPUs - no Docker!
    let guest_options = GuestOptionsBuilder::default()
        .build()
        .unwrap();
    let kernel_elf = guest_options.kernel();
    // Generate Rust source files for the methods crate.
    let guests = embed_method_metadata_with_options(HashMap::from([("guests", guest_options)]));

    if guests.is_empty() {
        panic!("expected at least one guest, found none");
    };
    
    // Use the first guest (or you can specify which one by name)
    let guest = &guests[0];
    println!("Using guest: {}", guest.name);

    let user_elf = std::fs::read(guest.path.to_string()).unwrap();
    let binary = ProgramBinary::new(&user_elf, &kernel_elf);
    let image_id = binary.compute_image_id().unwrap();
    let image_id_words = image_id.as_words().to_vec();
    let image_id_str = image_id.to_string();
    let mut elf_file = File::create("./artifacts/dcap-quote-verifier").unwrap();
    elf_file.write_all(binary.encode().as_slice()).unwrap();
    let mut methods_file = File::create("./src/methods.rs").unwrap();
    methods_file
        .write_all(
            format!(
                r##"
pub const DCAP_QUOTE_VERIFIER_ID: [u32; 8] = {image_id_words:?};
pub const DCAP_QUOTE_VERIFIER_ID_STR: &str = "{image_id_str}";
pub const DCAP_QUOTE_VERIFIER_ELF: &[u8] = include_bytes!("../artifacts/dcap-quote-verifier");
"##
            )
            .as_bytes(),
        )
        .unwrap();
}
