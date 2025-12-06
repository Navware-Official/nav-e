use std::env;
use std::path::PathBuf;

fn main() {
    // Use the shared proto file from the project root
    let proto_file = "../../proto/navigation.proto";
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    
    prost_build::Config::new()
        .out_dir(&out_dir)
        .compile_protos(&[proto_file], &["../../proto"])
        .expect("Failed to compile proto files");
    
    println!("cargo:rerun-if-changed={}", proto_file);
}
