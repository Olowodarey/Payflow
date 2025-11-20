// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.27;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BatchTf
 * @dev Upgradeable batch transfer contract for CELO and ERC20 tokens
 * Supports pausing and access control
 */
contract BatchTf is Initializable, PausableUpgradeable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // Reentrancy guard
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    event BatchTransferCompleted(
        address indexed sender,
        address indexed token,
        uint256 totalAmount,
        uint256 recipientCount
    );
    
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() internal {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() internal {
        _status = _NOT_ENTERED;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // For testing purposes, we don't disable initializers
        // In production, use a proxy pattern and uncomment the line below
        // _disableInitializers();
    }

    function initialize(address defaultAdmin, address pauser) public initializer {
        __Pausable_init();
        __AccessControl_init();
        _status = _NOT_ENTERED;

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Batch transfer CELO or ERC20 tokens
     * @param token Address of the ERC20 token (use address(0) for native CELO)
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to send to each recipient
     */
    function batchTransfer(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable nonReentrant whenNotPaused {
        require(recipients.length == amounts.length, "Length mismatch");
        require(recipients.length > 0, "Empty array");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        if (token == address(0)) {
            // Native CELO transfer
            require(msg.value == totalAmount, "Incorrect CELO amount");
            
            for (uint256 i = 0; i < recipients.length; i++) {
                require(recipients[i] != address(0), "Invalid address");
                (bool success, ) = payable(recipients[i]).call{value: amounts[i]}("");
                require(success, "Transfer failed");
            }
        } else {
            // ERC20 token transfer
            IERC20 tokenContract = IERC20(token);
            
            require(
                tokenContract.allowance(msg.sender, address(this)) >= totalAmount,
                "Insufficient allowance"
            );
            
            for (uint256 i = 0; i < recipients.length; i++) {
                require(recipients[i] != address(0), "Invalid address");
                tokenContract.safeTransferFrom(msg.sender, recipients[i], amounts[i]);
            }
        }
        
        emit BatchTransferCompleted(msg.sender, token, totalAmount, recipients.length);
    }

    /**
     * @dev Allow contract to receive CELO
     */
    receive() external payable {}
}
