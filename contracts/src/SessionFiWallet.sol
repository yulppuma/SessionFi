// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SessionFiWallet
 * @notice Core smart contract for session-based delegated execution with spending limits
 * @dev Implements scoped authorization for blockchain automation
 */
contract SessionFiWallet is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    /// @notice Session struct defining delegated execution boundaries
    struct Session {
        address owner;              // Session creator
        address sessionKey;         // Delegated executor key
        address allowedTarget;      // Only callable contract address
        bytes4 allowedSelector;     // Only callable function selector
        address allowedToken;       // Token to track spending
        uint256 maxAmount;          // Maximum spendable amount
        uint256 spentAmount;        // Amount already spent
        uint256 expiry;             // Session expiration timestamp
        uint256 nonce;              // Current nonce for replay protection
        uint256 maxNonce;           // Maximum nonce (max transactions)
        bool active;                // Session status
        uint256 createdAt;          // Session creation time
    }

    /// @notice Session execution record
    struct ExecutionRecord {
        uint256 sessionId;
        address target;
        bytes4 selector;
        uint256 amount;
        uint256 timestamp;
        bool success;
    }

    // ========== State Variables ==========

    mapping(uint256 => Session) public sessions;
    mapping(address => uint256[]) public userSessions;
    mapping(uint256 => ExecutionRecord[]) public executionHistory;

    uint256 public sessionCounter;
    uint256 public totalExecutions;

    /// @notice Emergency pause mechanism
    bool public paused;

    // ========== Events ==========

    event SessionCreated(
        uint256 indexed sessionId,
        address indexed owner,
        address sessionKey,
        address allowedTarget,
        bytes4 allowedSelector,
        uint256 maxAmount,
        uint256 expiry
    );

    event SessionExecuted(
        uint256 indexed sessionId,
        address indexed target,
        bytes4 selector,
        uint256 amount,
        uint256 newSpentAmount
    );

    event SessionRevoked(uint256 indexed sessionId, address indexed owner);

    event SessionExpired(uint256 indexed sessionId);

    event EmergencyPause(bool paused);

    event ExecutionAttempted(
        uint256 indexed sessionId,
        address indexed caller,
        bool success,
        string reason
    );

    // ========== Modifiers ==========

    modifier whenNotPaused() {
        require(!paused, "SessionFi: Protocol is paused");
        _;
    }

    modifier sessionExists(uint256 sessionId) {
        require(sessionId < sessionCounter, "SessionFi: Invalid session ID");
        _;
    }

    modifier onlySessionOwner(uint256 sessionId) {
        require(msg.sender == sessions[sessionId].owner, "SessionFi: Not session owner");
        _;
    }

    // ========== Session Management ==========

    /**
     * @notice Create a new delegated execution session
     * @param sessionKey Address that will execute delegated transactions
     * @param allowedTarget Target contract address
     * @param allowedSelector Function selector to allow
     * @param allowedToken Token to track spending (use address(0) for ETH)
     * @param maxAmount Maximum amount that can be spent
     * @param duration Session duration in seconds
     * @param maxNonce Maximum number of transactions allowed
     * @return sessionId ID of the created session
     */
    function createSession(
        address sessionKey,
        address allowedTarget,
        bytes4 allowedSelector,
        address allowedToken,
        uint256 maxAmount,
        uint256 duration,
        uint256 maxNonce
    ) external whenNotPaused returns (uint256) {
        require(sessionKey != address(0), "SessionFi: Invalid session key");
        require(allowedTarget != address(0), "SessionFi: Invalid target");
        require(maxAmount > 0, "SessionFi: Invalid max amount");
        require(duration > 0, "SessionFi: Invalid duration");
        require(maxNonce > 0, "SessionFi: Invalid max nonce");

        uint256 sessionId = sessionCounter++;
        uint256 expiry = block.timestamp + duration;

        sessions[sessionId] = Session({
            owner: msg.sender,
            sessionKey: sessionKey,
            allowedTarget: allowedTarget,
            allowedSelector: allowedSelector,
            allowedToken: allowedToken,
            maxAmount: maxAmount,
            spentAmount: 0,
            expiry: expiry,
            nonce: 0,
            maxNonce: maxNonce,
            active: true,
            createdAt: block.timestamp
        });

        userSessions[msg.sender].push(sessionId);

        emit SessionCreated(
            sessionId,
            msg.sender,
            sessionKey,
            allowedTarget,
            allowedSelector,
            maxAmount,
            expiry
        );

        return sessionId;
    }

    /**
     * @notice Execute a delegated transaction within session boundaries
     * @param sessionId Session ID to execute
     * @param target Target contract address
     * @param data Encoded function call
     * @param value ETH value to send (0 for token transfers)
     * @return success Whether execution succeeded
     */
    function executeSessionTransaction(
        uint256 sessionId,
        address target,
        bytes calldata data,
        uint256 value
    ) external payable nonReentrant whenNotPaused sessionExists(sessionId) returns (bool) {
        Session storage session = sessions[sessionId];

        // Validate session ownership and authorization
        require(msg.sender == session.sessionKey || msg.sender == session.owner, 
                "SessionFi: Not authorized");
        require(session.active, "SessionFi: Session not active");
        require(block.timestamp <= session.expiry, "SessionFi: Session expired");
        require(target == session.allowedTarget, "SessionFi: Unapproved target");

        // Validate function selector
        require(data.length >= 4, "SessionFi: Invalid call data");
        bytes4 selector = bytes4(data[:4]);
        require(selector == session.allowedSelector, "SessionFi: Unapproved function");

        // Validate spend limit
        require(session.spentAmount + value <= session.maxAmount, 
                "SessionFi: Spend limit exceeded");

        // Validate nonce
        require(session.nonce < session.maxNonce, "SessionFi: Max transactions exceeded");

        // Update session state
        session.spentAmount += value;
        session.nonce++;

        // Execute the transaction
        (bool success, bytes memory result) = target.call{value: value}(data);

        // Record execution
        executionHistory[sessionId].push(
            ExecutionRecord({
                sessionId: sessionId,
                target: target,
                selector: selector,
                amount: value,
                timestamp: block.timestamp,
                success: success
            })
        );

        totalExecutions++;

        if (!success) {
            emit ExecutionAttempted(sessionId, msg.sender, false, "Execution failed");
        } else {
            emit SessionExecuted(sessionId, target, selector, value, session.spentAmount);
            emit ExecutionAttempted(sessionId, msg.sender, true, "");
        }

        require(success, "SessionFi: Execution failed");
        return true;
    }

    /**
     * @notice Revoke an active session
     * @param sessionId Session ID to revoke
     */
    function revokeSession(uint256 sessionId) external sessionExists(sessionId) 
        onlySessionOwner(sessionId) {
        require(sessions[sessionId].active, "SessionFi: Session already revoked");
        sessions[sessionId].active = false;
        emit SessionRevoked(sessionId, msg.sender);
    }

    /**
     * @notice Emergency revoke (owner only)
     * @param sessionId Session ID to revoke
     */
    function emergencyRevokeSession(uint256 sessionId) external onlyOwner sessionExists(sessionId) {
        require(sessions[sessionId].active, "SessionFi: Session already revoked");
        sessions[sessionId].active = false;
        emit SessionRevoked(sessionId, sessions[sessionId].owner);
    }

    // ========== View Functions ==========

    /**
     * @notice Get session details
     * @param sessionId Session ID
     * @return Session data
     */
    function getSession(uint256 sessionId) 
        external 
        view 
        sessionExists(sessionId) 
        returns (Session memory) {
        return sessions[sessionId];
    }

    /**
     * @notice Check if session is valid for execution
     * @param sessionId Session ID
     * @return Whether session can be executed
     */
    function isSessionValid(uint256 sessionId) 
        external 
        view 
        sessionExists(sessionId) 
        returns (bool) {
        Session memory session = sessions[sessionId];
        return session.active && 
               block.timestamp <= session.expiry && 
               session.nonce < session.maxNonce;
    }

    /**
     * @notice Get time remaining for session
     * @param sessionId Session ID
     * @return Time remaining in seconds (0 if expired)
     */
    function getSessionTimeRemaining(uint256 sessionId) 
        external 
        view 
        sessionExists(sessionId) 
        returns (uint256) {
        Session memory session = sessions[sessionId];
        if (block.timestamp >= session.expiry) {
            return 0;
        }
        return session.expiry - block.timestamp;
    }

    /**
     * @notice Get spending percentage for session
     * @param sessionId Session ID
     * @return Percentage of max amount spent (0-100)
     */
    function getSpendingPercentage(uint256 sessionId) 
        external 
        view 
        sessionExists(sessionId) 
        returns (uint256) {
        Session memory session = sessions[sessionId];
        if (session.maxAmount == 0) return 0;
        return (session.spentAmount * 100) / session.maxAmount;
    }

    /**
     * @notice Get user's active sessions
     * @param user User address
     * @return Array of active session IDs
     */
    function getUserActiveSessions(address user) 
        external 
        view 
        returns (uint256[] memory) {
        uint256[] memory allSessions = userSessions[user];
        uint256 activeCount = 0;

        // Count active sessions
        for (uint256 i = 0; i < allSessions.length; i++) {
            if (sessions[allSessions[i]].active) {
                activeCount++;
            }
        }

        // Build active sessions array
        uint256[] memory activeSessions = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allSessions.length; i++) {
            if (sessions[allSessions[i]].active) {
                activeSessions[index++] = allSessions[i];
            }
        }

        return activeSessions;
    }

    /**
     * @notice Get all user sessions (active and revoked)
     * @param user User address
     * @return Array of all session IDs
     */
    function getUserSessions(address user) 
        external 
        view 
        returns (uint256[] memory) {
        return userSessions[user];
    }

    /**
     * @notice Get execution history for session
     * @param sessionId Session ID
     * @return Array of execution records
     */
    function getExecutionHistory(uint256 sessionId) 
        external 
        view 
        sessionExists(sessionId) 
        returns (ExecutionRecord[] memory) {
        return executionHistory[sessionId];
    }

    /**
     * @notice Get execution count for session
     * @param sessionId Session ID
     * @return Number of executions
     */
    function getExecutionCount(uint256 sessionId) 
        external 
        view 
        sessionExists(sessionId) 
        returns (uint256) {
        return executionHistory[sessionId].length;
    }

    // ========== Emergency Controls ==========

    /**
     * @notice Pause protocol (owner only)
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit EmergencyPause(_paused);
    }

    /**
     * @notice Get contract statistics
     * @return Total sessions created
     * @return Total transactions executed
     */
    function getStats() external view returns (uint256, uint256) {
        return (sessionCounter, totalExecutions);
    }

    // ========== Fallback ==========

    /**
     * @notice Allow contract to receive ETH
     */
    receive() external payable {}
}
