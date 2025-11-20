// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Gigipay} from "../src/Gigipay.sol";
import {IGigipayEvents} from "../src/interfaces/IGigipayEvents.sol";
import {IGigipayErrors} from "../src/interfaces/IGigipayErrors.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CodePaymentTest is Test, IGigipayEvents, IGigipayErrors {
    Gigipay public gigipay;
    
    address public admin;
    address public pauser;
    address public sender;
    address public claimer1;
    address public claimer2;
    
    // Test claim codes
    string constant CODE1 = "SECRET123";
    string constant CODE2 = "GIFT2024";
    string constant CODE3 = "PROMO999";
    string constant WRONG_CODE = "WRONGCODE";
    
    function setUp() public {
        // Create test addresses
        admin = makeAddr("admin");
        pauser = makeAddr("pauser");
        sender = makeAddr("sender");
        claimer1 = makeAddr("claimer1");
        claimer2 = makeAddr("claimer2");
        
        // Deploy implementation
        Gigipay implementation = new Gigipay();
        
        // Deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(
            Gigipay.initialize.selector,
            admin,
            pauser
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        gigipay = Gigipay(payable(address(proxy)));
        
        // Fund sender with CELO
        vm.deal(sender, 100 ether);
    }
    
    function test_CreateSingleVoucher() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit VoucherCreated(0, sender, amount, expiresAt);
        
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // Verify voucher was created
        assertEq(voucherId, 0, "First voucher should have ID 0");
        
        // Check voucher details
        (
            address voucherSender,
            uint256 voucherAmount,
            ,
            uint256 voucherExpiresAt,
            bool claimed,
            bool refunded
        ) = gigipay.vouchers(voucherId);
        
        assertEq(voucherSender, sender, "Sender mismatch");
        assertEq(voucherAmount, amount, "Amount mismatch");
        assertEq(voucherExpiresAt, expiresAt, "Expiration mismatch");
        assertFalse(claimed, "Should not be claimed");
        assertFalse(refunded, "Should not be refunded");
        
        console.log("[SUCCESS] Single voucher created with ID:", voucherId);
        console.log("  Amount:", amount);
        console.log("  Expires at:", expiresAt);
    }
    
    function test_CreateBatchVouchers() public {
        string[] memory codes = new string[](3);
        codes[0] = CODE1;
        codes[1] = CODE2;
        codes[2] = CODE3;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;
        amounts[2] = 3 ether;
        
        uint256[] memory expirationTimes = new uint256[](3);
        expirationTimes[0] = block.timestamp + 1 days;
        expirationTimes[1] = block.timestamp + 7 days;
        expirationTimes[2] = block.timestamp + 30 days;
        
        uint256 totalAmount = 6 ether;
        
        vm.prank(sender);
        uint256[] memory voucherIds = gigipay.createVoucherBatch{value: totalAmount}(
            codes,
            amounts,
            expirationTimes
        );
        
        // Verify all vouchers were created
        assertEq(voucherIds.length, 3, "Should create 3 vouchers");
        assertEq(voucherIds[0], 0, "First voucher ID");
        assertEq(voucherIds[1], 1, "Second voucher ID");
        assertEq(voucherIds[2], 2, "Third voucher ID");
        
        // Check sender's vouchers
        uint256[] memory senderVouchers = gigipay.getSenderVouchers(sender);
        assertEq(senderVouchers.length, 3, "Sender should have 3 vouchers");
        
        console.log("[SUCCESS] Batch created 3 vouchers");
        console.log("  Voucher 0: 1 CELO, expires in 1 day");
        console.log("  Voucher 1: 2 CELO, expires in 7 days");
        console.log("  Voucher 2: 3 CELO, expires in 30 days");
    }
    
    function test_ClaimVoucherWithCorrectCode() public {
        uint256 amount = 5 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        uint256 claimerBalanceBefore = claimer1.balance;
        
        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit VoucherClaimed(voucherId, claimer1, amount);
        
        // Claim voucher
        vm.prank(claimer1);
        gigipay.claimVoucher(voucherId, CODE1);
        
        // Verify claim
        (, , , , bool claimed, ) = gigipay.vouchers(voucherId);
        assertTrue(claimed, "Voucher should be claimed");
        assertEq(claimer1.balance, claimerBalanceBefore + amount, "Claimer should receive funds");
        
        console.log("[SUCCESS] Voucher claimed successfully");
        console.log("  Claimer received:", amount);
    }
    
    function test_RevertClaimWithWrongCode() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // Try to claim with wrong code
        vm.prank(claimer1);
        vm.expectRevert(InvalidClaimCode.selector);
        gigipay.claimVoucher(voucherId, WRONG_CODE);
        
        console.log("[SUCCESS] Rejected claim with wrong code");
    }
    
    function test_RevertClaimExpiredVoucher() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 1 hours;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 2 hours);
        
        // Try to claim expired voucher
        vm.prank(claimer1);
        vm.expectRevert(VoucherExpired.selector);
        gigipay.claimVoucher(voucherId, CODE1);
        
        console.log("[SUCCESS] Rejected claim of expired voucher");
    }
    
    function test_RevertDoubleClaimVoucher() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // First claim succeeds
        vm.prank(claimer1);
        gigipay.claimVoucher(voucherId, CODE1);
        
        // Second claim should fail
        vm.prank(claimer2);
        vm.expectRevert(VoucherAlreadyClaimed.selector);
        gigipay.claimVoucher(voucherId, CODE1);
        
        console.log("[SUCCESS] Prevented double claim");
    }
    
    function test_RefundExpiredVoucher() public {
        uint256 amount = 2 ether;
        uint256 expiresAt = block.timestamp + 1 hours;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        uint256 senderBalanceBefore = sender.balance;
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 2 hours);
        
        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit VoucherRefunded(voucherId, sender, amount);
        
        // Refund voucher
        vm.prank(sender);
        gigipay.refundVoucher(voucherId);
        
        // Verify refund
        (, , , , , bool refunded) = gigipay.vouchers(voucherId);
        assertTrue(refunded, "Voucher should be refunded");
        assertEq(sender.balance, senderBalanceBefore + amount, "Sender should receive refund");
        
        console.log("[SUCCESS] Expired voucher refunded");
        console.log("  Refund amount:", amount);
    }
    
    function test_RevertRefundBeforeExpiration() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // Try to refund before expiration
        vm.prank(sender);
        vm.expectRevert(VoucherNotExpired.selector);
        gigipay.refundVoucher(voucherId);
        
        console.log("[SUCCESS] Prevented refund before expiration");
    }
    
    function test_RevertRefundClaimedVoucher() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // Claim voucher
        vm.prank(claimer1);
        gigipay.claimVoucher(voucherId, CODE1);
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 8 days);
        
        // Try to refund claimed voucher
        vm.prank(sender);
        vm.expectRevert(VoucherAlreadyClaimed.selector);
        gigipay.refundVoucher(voucherId);
        
        console.log("[SUCCESS] Prevented refund of claimed voucher");
    }
    
    function test_IsVoucherClaimable() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // Should be claimable
        assertTrue(gigipay.isVoucherClaimable(voucherId), "Should be claimable");
        
        // Claim it
        vm.prank(claimer1);
        gigipay.claimVoucher(voucherId, CODE1);
        
        // Should no longer be claimable
        assertFalse(gigipay.isVoucherClaimable(voucherId), "Should not be claimable after claim");
        
        console.log("[SUCCESS] isVoucherClaimable works correctly");
    }
    
    function test_IsVoucherRefundable() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 1 hours;
        
        // Create voucher
        vm.prank(sender);
        uint256 voucherId = gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        // Should not be refundable yet
        assertFalse(gigipay.isVoucherRefundable(voucherId), "Should not be refundable before expiry");
        
        // Fast forward past expiration
        vm.warp(block.timestamp + 2 hours);
        
        // Should be refundable now
        assertTrue(gigipay.isVoucherRefundable(voucherId), "Should be refundable after expiry");
        
        console.log("[SUCCESS] isVoucherRefundable works correctly");
    }
    
    function test_RevertCreateVoucherWithZeroAmount() public {
        uint256 expiresAt = block.timestamp + 7 days;
        
        vm.prank(sender);
        vm.expectRevert(InvalidAmount.selector);
        gigipay.createVoucher{value: 0}(CODE1, expiresAt);
        
        console.log("[SUCCESS] Prevented voucher creation with zero amount");
    }
    
    function test_RevertCreateVoucherWithPastExpiration() public {
        uint256 amount = 1 ether;
        
        // Warp to a future time first so we can subtract
        vm.warp(block.timestamp + 10 days);
        uint256 pastTime = block.timestamp - 1 days;
        
        vm.prank(sender);
        vm.expectRevert(InvalidExpirationTime.selector);
        gigipay.createVoucher{value: amount}(CODE1, pastTime);
        
        console.log("[SUCCESS] Prevented voucher with past expiration");
    }
    
    function test_RevertCreateVoucherWithEmptyCode() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        vm.prank(sender);
        vm.expectRevert(InvalidClaimCode.selector);
        gigipay.createVoucher{value: amount}("", expiresAt);
        
        console.log("[SUCCESS] Prevented voucher with empty code");
    }
    
    function test_MultipleSendersMultipleVouchers() public {
        address sender2 = makeAddr("sender2");
        vm.deal(sender2, 10 ether);
        
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Sender 1 creates 2 vouchers
        vm.startPrank(sender);
        gigipay.createVoucher{value: 1 ether}(CODE1, expiresAt);
        gigipay.createVoucher{value: 2 ether}(CODE2, expiresAt);
        vm.stopPrank();
        
        // Sender 2 creates 1 voucher
        vm.prank(sender2);
        gigipay.createVoucher{value: 3 ether}(CODE3, expiresAt);
        
        // Check sender vouchers
        uint256[] memory sender1Vouchers = gigipay.getSenderVouchers(sender);
        uint256[] memory sender2Vouchers = gigipay.getSenderVouchers(sender2);
        
        assertEq(sender1Vouchers.length, 2, "Sender 1 should have 2 vouchers");
        assertEq(sender2Vouchers.length, 1, "Sender 2 should have 1 voucher");
        
        console.log("[SUCCESS] Multiple senders can create vouchers independently");
        console.log("  Sender 1 vouchers:", sender1Vouchers.length);
        console.log("  Sender 2 vouchers:", sender2Vouchers.length);
    }
    
    function test_VoucherWhenPaused() public {
        uint256 amount = 1 ether;
        uint256 expiresAt = block.timestamp + 7 days;
        
        // Pause contract
        vm.prank(pauser);
        gigipay.pause();
        
        // Try to create voucher when paused
        vm.prank(sender);
        vm.expectRevert();
        gigipay.createVoucher{value: amount}(CODE1, expiresAt);
        
        console.log("[SUCCESS] Prevented voucher creation when paused");
    }
}