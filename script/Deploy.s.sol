// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TdxProofVerifier} from "../src/TdxProofVerifier.sol";

contract DeployWithRealVerifierScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Use the official RISC Zero verifier router on Base Sepolia
        address riscZeroRouter = 0x0b144E07A0826182B6b59788c34b32Bfa86Fb711;
        
        console.log("Deploying TdxProofVerifier with RISC Zero router:", riscZeroRouter);
        
        // Deploy the TdxProofVerifier with the real router
        TdxProofVerifier verifier = new TdxProofVerifier(riscZeroRouter);
        
        vm.stopBroadcast();

        console.log("TdxProofVerifier deployed to:", address(verifier));
        console.log("Using RISC Zero router:", riscZeroRouter);
        console.log("");
        console.log("Contract details:");
        console.log("- Image ID:", vm.toString(verifier.TDX_VERIFIER_IMAGE_ID()));
        console.log("- Verifier:", address(verifier.verifier()));
        console.log("");
        console.log("Next steps:");
        console.log("1. Update your .env with VERIFIER_ADDRESS=", vm.toString(address(verifier)));
        console.log("2. Use SubmitRealProof.s.sol to submit your actual proof");
        console.log("3. The router will automatically route to the correct verifier based on your seal selector");
    }
}
