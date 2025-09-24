// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/OurRiscZeroGroth16Verifier.sol";

/**
 * @title DeployOurVerifier
 * @dev Script to deploy our custom RISC Zero Groth16 verifier
 */
contract DeployOurVerifier is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING OUR RISC ZERO GROTH16 VERIFIER ===");
        console.log("Account:", deployer);
        console.log("Balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy our custom verifier
        OurRiscZeroGroth16Verifier verifier = new OurRiscZeroGroth16Verifier();
        
        vm.stopBroadcast();
        
        console.log("=== DEPLOYMENT SUCCESSFUL ===");
        console.log("Verifier deployed to:", address(verifier));
        console.log("Image ID:", vm.toString(verifier.IMAGE_ID()));
        
        console.log("Deployment completed successfully!");
    }
}
