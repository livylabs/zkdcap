// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/DCAPQuoteApp.sol";

/**
 * @title DeployDCAPQuoteApp
 * @dev Script to deploy the DCAP Quote Application contract
 */
contract DeployDCAPQuoteApp is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING DCAP QUOTE APPLICATION ===");
        console.log("Account:", deployer);
        console.log("Balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the DCAP Quote Application
        DCAPQuoteApp dcapApp = new DCAPQuoteApp();
        
        vm.stopBroadcast();
        
        console.log("=== DEPLOYMENT SUCCESSFUL ===");
        console.log("DCAP Quote App deployed to:", address(dcapApp));
        console.log("Image ID:", vm.toString(dcapApp.getImageId()));
        console.log("Deployment completed successfully!");
        console.log("This app can verify DCAP quotes from our custom program.");
    }
}
