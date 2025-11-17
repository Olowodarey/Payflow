// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {BatchTf} from "../src/batchtf.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BatchTfTest is Test {
    BatchTf public batchTf;
    MockERC20 public mockToken;
    
    address public admin;
    address public pauser;
    address public sender;
    
    // 4 recipient wallets
    address public recipient1;
    address public recipient2;
    address public recipient3;
    address public recipient4;
    
    function setUp() public {
        // Create test addresses
        admin = makeAddr("admin");
        pauser = makeAddr("pauser");
        sender = makeAddr("sender");
        
        recipient1 = makeAddr("recipient1");
        recipient2 = makeAddr("recipient2");
        recipient3 = makeAddr("recipient3");
        recipient4 = makeAddr("recipient4");
        
        // Deploy contracts
        batchTf = new BatchTf();
        batchTf.initialize(admin, pauser);
        
        // Deploy mock ERC20 token
        mockToken = new MockERC20();
        
        // Fund sender with CELO and tokens
        vm.deal(sender, 100 ether);
        mockToken.mint(sender, 10000 * 10**18);
    }
    
    function test_BatchTransferNativeCELO() public {
        // Prepare batch transfer data for 4 wallets
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;
        amounts[2] = 3 ether;
        amounts[3] = 4 ether;
        
        uint256 totalAmount = 10 ether;
        
        // Record initial balances
        uint256 recipient1BalanceBefore = recipient1.balance;
        uint256 recipient2BalanceBefore = recipient2.balance;
        uint256 recipient3BalanceBefore = recipient3.balance;
        uint256 recipient4BalanceBefore = recipient4.balance;
        
        // Execute batch transfer as sender
        vm.prank(sender);
        batchTf.batchTransfer{value: totalAmount}(address(0), recipients, amounts);
        
        // Verify all 4 recipients received correct amounts
        assertEq(recipient1.balance, recipient1BalanceBefore + 1 ether, "Recipient 1 balance incorrect");
        assertEq(recipient2.balance, recipient2BalanceBefore + 2 ether, "Recipient 2 balance incorrect");
        assertEq(recipient3.balance, recipient3BalanceBefore + 3 ether, "Recipient 3 balance incorrect");
        assertEq(recipient4.balance, recipient4BalanceBefore + 4 ether, "Recipient 4 balance incorrect");
        
        console.log("[SUCCESS] All 4 wallets received native CELO successfully");
        console.log("  Recipient 1:", recipient1.balance);
        console.log("  Recipient 2:", recipient2.balance);
        console.log("  Recipient 3:", recipient3.balance);
        console.log("  Recipient 4:", recipient4.balance);
    }
    
    function test_BatchTransferERC20Tokens() public {
        // Prepare batch transfer data for 4 wallets
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100 * 10**18;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;
        amounts[3] = 400 * 10**18;
        
        uint256 totalAmount = 1000 * 10**18;
        
        // Sender approves contract to spend tokens
        vm.startPrank(sender);
        mockToken.approve(address(batchTf), totalAmount);
        
        // Record initial balances
        uint256 recipient1BalanceBefore = mockToken.balanceOf(recipient1);
        uint256 recipient2BalanceBefore = mockToken.balanceOf(recipient2);
        uint256 recipient3BalanceBefore = mockToken.balanceOf(recipient3);
        uint256 recipient4BalanceBefore = mockToken.balanceOf(recipient4);
        
        // Execute batch transfer
        batchTf.batchTransfer(address(mockToken), recipients, amounts);
        vm.stopPrank();
        
        // Verify all 4 recipients received correct token amounts
        assertEq(mockToken.balanceOf(recipient1), recipient1BalanceBefore + 100 * 10**18, "Recipient 1 token balance incorrect");
        assertEq(mockToken.balanceOf(recipient2), recipient2BalanceBefore + 200 * 10**18, "Recipient 2 token balance incorrect");
        assertEq(mockToken.balanceOf(recipient3), recipient3BalanceBefore + 300 * 10**18, "Recipient 3 token balance incorrect");
        assertEq(mockToken.balanceOf(recipient4), recipient4BalanceBefore + 400 * 10**18, "Recipient 4 token balance incorrect");
        
        console.log("[SUCCESS] All 4 wallets received ERC20 tokens successfully");
        console.log("  Recipient 1:", mockToken.balanceOf(recipient1) / 10**18, "tokens");
        console.log("  Recipient 2:", mockToken.balanceOf(recipient2) / 10**18, "tokens");
        console.log("  Recipient 3:", mockToken.balanceOf(recipient3) / 10**18, "tokens");
        console.log("  Recipient 4:", mockToken.balanceOf(recipient4) / 10**18, "tokens");
    }
    
    function test_BatchTransferEmitsEvent() public {
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;
        amounts[3] = 1 ether;
        
        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit BatchTf.BatchTransferCompleted(sender, address(0), 4 ether, 4);
        
        vm.prank(sender);
        batchTf.batchTransfer{value: 4 ether}(address(0), recipients, amounts);
    }
    
    function test_RevertWhenArrayLengthMismatch() public {
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](3); // Wrong length
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;
        
        vm.prank(sender);
        vm.expectRevert("Length mismatch");
        batchTf.batchTransfer{value: 3 ether}(address(0), recipients, amounts);
    }
    
    function test_RevertWhenInsufficientCELO() public {
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;
        amounts[3] = 1 ether;
        
        vm.prank(sender);
        vm.expectRevert("Incorrect CELO amount");
        batchTf.batchTransfer{value: 3 ether}(address(0), recipients, amounts); // Sent 3 instead of 4
    }
    
    function test_RevertWhenInsufficientAllowance1() public {
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100 * 10**18;
        amounts[1] = 100 * 10**18;
        amounts[2] = 100 * 10**18;
        amounts[3] = 100 * 10**18;
        
        // Don't approve tokens
        vm.prank(sender);
        vm.expectRevert("Insufficient allowance");
        batchTf.batchTransfer(address(mockToken), recipients, amounts);
    }
    
    function test_RevertWhenPaused() public {
        // Pause the contract
        vm.prank(pauser);
        batchTf.pause();
        
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;
        amounts[3] = 1 ether;
        
        vm.prank(sender);
        vm.expectRevert();
        batchTf.batchTransfer{value: 4 ether}(address(0), recipients, amounts);
    }

     function test_RevertWhenInsufficientAllowance() public {
        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100 * 10**18;
        amounts[1] = 100 * 10**18;
        amounts[2] = 100 * 10**18;
        amounts[3] = 100 * 10**18;
        
        // Don't approve tokens
        vm.prank(sender);
        vm.expectRevert("Insufficient allowance");
        batchTf.batchTransfer(address(mockToken), recipients, amounts);
    }
}
