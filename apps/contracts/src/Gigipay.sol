// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IGigipayErrors} from "./interfaces/IGigipayErrors.sol";
import {IGigipayEvents} from "./interfaces/IGigipayEvents.sol";

contract Gigipay is Initializable, PausableUpgradeable, AccessControlUpgradeable, IGigipayErrors, IGigipayEvents {
    using SafeERC20 for IERC20;
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Payment Voucher System
    struct PaymentVoucher {
        address sender;
        uint256 amount;
        bytes32 claimCodeHash; // keccak256(abi.encodePacked(claimCode))
        uint256 expiresAt;
        bool claimed;
        bool refunded;
    }

    // Counter for unique voucher IDs
    uint256 private _voucherIdCounter;
    
    // Mapping from voucher ID to PaymentVoucher
    mapping(uint256 => PaymentVoucher) public vouchers;
    
    // Mapping from sender to their voucher IDs
    mapping(address => uint256[]) public senderVouchers;
    
    // Reentrancy guard
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Gas-optimized keccak256 hashing using assembly
     * @param _claimCode The claim code to hash
     * @return result The keccak256 hash of the claim code
     */
    function _hashClaimCode(string memory _claimCode) internal pure returns (bytes32 result) {
        bytes memory packed = abi.encodePacked(_claimCode);
        assembly {
            result := keccak256(add(packed, 0x20), mload(packed))
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() internal {
        if (_status == _ENTERED) revert TransferFailed(); // Reusing error for reentrancy
        _status = _ENTERED;
    }

    function _nonReentrantAfter() internal {
        _status = _NOT_ENTERED;
    }

    function initialize(address defaultAdmin, address pauser) public initializer {
        __Pausable_init();
        __AccessControl_init();
        _status = _NOT_ENTERED;

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
    }

    /**
     * @notice Create a single payment voucher with a claim code
     * @param claimCode The secret code that can be used to claim this voucher
     * @param expirationTime The timestamp when this voucher expires
     * @return voucherId The ID of the created voucher
     */
    function createVoucher(
        string memory claimCode,
        uint256 expirationTime
    ) public payable whenNotPaused returns (uint256) {
        if (msg.value == 0) revert InvalidAmount();
        if (expirationTime <= block.timestamp) revert InvalidExpirationTime();
        if (bytes(claimCode).length == 0) revert InvalidClaimCode();

        uint256 voucherId = _voucherIdCounter++;
        bytes32 claimCodeHash = _hashClaimCode(claimCode);

        vouchers[voucherId] = PaymentVoucher({
            sender: msg.sender,
            amount: msg.value,
            claimCodeHash: claimCodeHash,
            expiresAt: expirationTime,
            claimed: false,
            refunded: false
        });

        senderVouchers[msg.sender].push(voucherId);

        emit VoucherCreated(voucherId, msg.sender, msg.value, expirationTime);

        return voucherId;
    }

    /**
     * @notice Create multiple payment vouchers in one transaction (gas efficient!)
     * @param claimCodes Array of secret codes for each voucher
     * @param amounts Array of amounts for each voucher
     * @param expirationTimes Array of expiration timestamps for each voucher
     * @return voucherIds Array of created voucher IDs
     */
    function createVoucherBatch(
        string[] memory claimCodes,
        uint256[] memory amounts,
        uint256[] memory expirationTimes
    ) public payable whenNotPaused returns (uint256[] memory) {
        uint256 length = claimCodes.length;
        if (length != amounts.length || length != expirationTimes.length) {
            revert InvalidAmount();
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < length; i++) {
            totalAmount += amounts[i];
        }
        if (msg.value != totalAmount) revert InvalidAmount();

        uint256[] memory voucherIds = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            if (amounts[i] == 0) revert InvalidAmount();
            if (expirationTimes[i] <= block.timestamp) revert InvalidExpirationTime();
            if (bytes(claimCodes[i]).length == 0) revert InvalidClaimCode();

            uint256 voucherId = _voucherIdCounter++;
            bytes32 claimCodeHash = _hashClaimCode(claimCodes[i]);

            vouchers[voucherId] = PaymentVoucher({
                sender: msg.sender,
                amount: amounts[i],
                claimCodeHash: claimCodeHash,
                expiresAt: expirationTimes[i],
                claimed: false,
                refunded: false
            });

            senderVouchers[msg.sender].push(voucherId);
            voucherIds[i] = voucherId;

            emit VoucherCreated(voucherId, msg.sender, amounts[i], expirationTimes[i]);
        }

        return voucherIds;
    }

    /**
     * @notice Claim a payment voucher using the claim code
     * @param voucherId The ID of the voucher to claim
     * @param claimCode The secret code to unlock the voucher
     */
    function claimVoucher(
        uint256 voucherId,
        string memory claimCode
    ) public whenNotPaused {
        PaymentVoucher storage voucher = vouchers[voucherId];
        
        if (voucher.sender == address(0)) revert VoucherNotFound();
        if (voucher.claimed) revert VoucherAlreadyClaimed();
        if (voucher.refunded) revert VoucherAlreadyRefunded();
        if (block.timestamp > voucher.expiresAt) revert VoucherExpired();

        bytes32 providedCodeHash = _hashClaimCode(claimCode);
        if (providedCodeHash != voucher.claimCodeHash) revert InvalidClaimCode();

        voucher.claimed = true;

        (bool success, ) = payable(msg.sender).call{value: voucher.amount}("");
        if (!success) revert TransferFailed();

        emit VoucherClaimed(voucherId, msg.sender, voucher.amount);
    }

    /**
     * @notice Refund an expired voucher back to the sender
     * @param voucherId The ID of the voucher to refund
     */
    function refundVoucher(uint256 voucherId) public whenNotPaused {
        PaymentVoucher storage voucher = vouchers[voucherId];
        
        if (voucher.sender == address(0)) revert VoucherNotFound();
        if (voucher.claimed) revert VoucherAlreadyClaimed();
        if (voucher.refunded) revert VoucherAlreadyRefunded();
        if (block.timestamp <= voucher.expiresAt) revert VoucherNotExpired();
        if (msg.sender != voucher.sender) revert InvalidClaimCode(); // Reusing error for unauthorized access

        voucher.refunded = true;

        (bool success, ) = payable(voucher.sender).call{value: voucher.amount}("");
        if (!success) revert TransferFailed();

        emit VoucherRefunded(voucherId, voucher.sender, voucher.amount);
    }

    /**
     * @notice Get all voucher IDs created by a sender
     * @param sender The address of the sender
     * @return Array of voucher IDs
     */
    function getSenderVouchers(address sender) public view returns (uint256[] memory) {
        return senderVouchers[sender];
    }

    /**
     * @notice Check if a voucher is claimable (not claimed, not refunded, not expired)
     * @param voucherId The ID of the voucher to check
     * @return True if the voucher can be claimed
     */
    function isVoucherClaimable(uint256 voucherId) public view returns (bool) {
        PaymentVoucher memory voucher = vouchers[voucherId];
        return voucher.sender != address(0) &&
               !voucher.claimed &&
               !voucher.refunded &&
               block.timestamp <= voucher.expiresAt;
    }

    /**
     * @notice Check if a voucher is refundable (not claimed, not refunded, expired)
     * @param voucherId The ID of the voucher to check
     * @return True if the voucher can be refunded
     */
    function isVoucherRefundable(uint256 voucherId) public view returns (bool) {
        PaymentVoucher memory voucher = vouchers[voucherId];
        return voucher.sender != address(0) &&
               !voucher.claimed &&
               !voucher.refunded &&
               block.timestamp > voucher.expiresAt;
    }

    /**
     * @notice Batch transfer native CELO or ERC20 tokens to multiple recipients
     * @param token Address of the ERC20 token (use address(0) for native CELO)
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to send to each recipient
     */
    function batchTransfer(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable nonReentrant whenNotPaused {
        if (recipients.length != amounts.length) revert LengthMismatch();
        if (recipients.length == 0) revert EmptyArray();
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        if (token == address(0)) {
            // Native CELO transfer
            if (msg.value != totalAmount) revert IncorrectNativeAmount();
            
            for (uint256 i = 0; i < recipients.length; i++) {
                if (recipients[i] == address(0)) revert InvalidRecipient();
                (bool success, ) = payable(recipients[i]).call{value: amounts[i]}("");
                if (!success) revert TransferFailed();
            }
        } else {
            // ERC20 token transfer
            IERC20 tokenContract = IERC20(token);
            
            if (tokenContract.allowance(msg.sender, address(this)) < totalAmount) {
                revert InsufficientAllowance();
            }
            
            for (uint256 i = 0; i < recipients.length; i++) {
                if (recipients[i] == address(0)) revert InvalidRecipient();
                tokenContract.safeTransferFrom(msg.sender, recipients[i], amounts[i]);
            }
        }
        
        emit BatchTransferCompleted(msg.sender, token, totalAmount, recipients.length);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Allow contract to receive native CELO
     */
    receive() external payable {}
}
