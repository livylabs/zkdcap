// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/QuoteVerifier.sol";

/**
 * @title DeployVerifier
 * @dev Deployment script for QuoteVerifier contract
 */
contract DeployVerifier is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying QuoteVerifier with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        QuoteVerifier verifier = new QuoteVerifier();
        
        vm.stopBroadcast();
        
        console.log("QuoteVerifier deployed to:", address(verifier));
        console.logBytes32(verifier.getImageId());
        
        // Verify deployment
        require(address(verifier) != address(0), "Deployment failed");
        require(verifier.getImageId() == 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a, "Image ID mismatch");
        
        console.log("Deployment successful!");
    }
}
