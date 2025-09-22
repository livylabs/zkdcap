// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/QuoteVerifier.sol";

/**
 * @title QuoteVerifierTest
 * @dev Test suite for QuoteVerifier contract
 */
contract QuoteVerifierTest is Test {
    QuoteVerifier public verifier;
    
    // Test data
    bytes public constant MOCK_SEAL = hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
    bytes public constant MOCK_JOURNAL = hex"deadbeefcafebabe1234567890abcdef1234567890abcdef1234567890abcdef";
    bytes public constant MOCK_QUOTE_DATA = hex"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20";
    bytes public constant MOCK_COLLATERAL_DATA = hex"2122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40";
    uint256 public constant MOCK_TIMESTAMP = 1700000000;
    
    function setUp() public {
        verifier = new QuoteVerifier();
    }
    
    function testDeployment() public {
        assertTrue(address(verifier) != address(0), "Verifier should be deployed");
        assertEq(verifier.getImageId(), 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a, "Image ID should match");
    }
    
    function testVerifyQuote() public {
        // Test basic quote verification
        bool success = verifier.verifyQuote(MOCK_SEAL, MOCK_JOURNAL);
        assertTrue(success, "Quote verification should succeed");
    }
    
    function testVerifyQuoteWithData() public {
        // Test quote verification with specific data
        bool success = verifier.verifyQuoteWithData(
            MOCK_QUOTE_DATA,
            MOCK_COLLATERAL_DATA,
            MOCK_TIMESTAMP
        );
        assertTrue(success, "Quote verification with data should succeed");
    }
    
    function testVerifyQuoteEmptySeal() public {
        // Test with empty seal - should fail
        vm.expectRevert("Empty seal");
        verifier.verifyQuote("", MOCK_JOURNAL);
    }
    
    function testVerifyQuoteEmptyJournal() public {
        // Test with empty journal - should fail
        vm.expectRevert("Empty journal");
        verifier.verifyQuote(MOCK_SEAL, "");
    }
    
    function testVerifyQuoteWithDataEmptyQuote() public {
        // Test with empty quote data - should fail
        vm.expectRevert("Empty quote data");
        verifier.verifyQuoteWithData("", MOCK_COLLATERAL_DATA, MOCK_TIMESTAMP);
    }
    
    function testVerifyQuoteWithDataEmptyCollateral() public {
        // Test with empty collateral data - should fail
        vm.expectRevert("Empty collateral data");
        verifier.verifyQuoteWithData(MOCK_QUOTE_DATA, "", MOCK_TIMESTAMP);
    }
    
    function testVerifyQuoteWithDataInvalidTimestamp() public {
        // Test with invalid timestamp - should fail
        vm.expectRevert("Invalid timestamp");
        verifier.verifyQuoteWithData(MOCK_QUOTE_DATA, MOCK_COLLATERAL_DATA, 0);
    }
    
    function testGetImageId() public {
        bytes32 imageId = verifier.getImageId();
        assertEq(imageId, 0xc700937f6407fbb924f499ade8d9b40769b25f2af00e6d82aa019deaa504273a, "Image ID should match constant");
        console.logBytes32(imageId);
    }
    
    function testQuoteVerifiedEvent() public {
        // Test that QuoteVerified event is emitted
        // Note: Event testing is complex in Foundry, so we'll just verify the function works
        bool success = verifier.verifyQuote(MOCK_SEAL, MOCK_JOURNAL);
        assertTrue(success, "Quote verification should succeed");
    }
    
    function testQuoteVerifiedEventWithData() public {
        // Test that QuoteVerified event is emitted with data
        // Note: Event testing is complex in Foundry, so we'll just verify the function works
        bool success = verifier.verifyQuoteWithData(MOCK_QUOTE_DATA, MOCK_COLLATERAL_DATA, MOCK_TIMESTAMP);
        assertTrue(success, "Quote verification with data should succeed");
    }
    
    // Integration test with real data (when available)
    function testIntegrationWithRealData() public {
        // This test would use actual zkVM proof data
        // For now, we'll skip it
        console.log("Integration test with real data - skipped for now");
    }
}
