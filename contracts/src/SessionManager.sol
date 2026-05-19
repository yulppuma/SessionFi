// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title SessionManager
 * @notice Manages session metadata, permissions, and lifecycle
 * @dev Complements SessionFiWallet with additional metadata tracking
 */
contract SessionManager is Ownable, ReentrancyGuard {

    /// @notice Session metadata
    struct SessionMetadata {
        string name;
        string description;
        address[] allowedTokens;
        uint256 createdAt;
        uint256 updatedAt;
    }

    /// @notice Permission level enum
    enum PermissionLevel {
        NONE,
        VIEW,
        EXECUTE,
        REVOKE,
        MANAGE
    }

    /// @notice User permissions for session
    struct UserPermission {
        PermissionLevel level;
        uint256 grantedAt;
        uint256 expiresAt;
    }

    // ========== State Variables ==========

    mapping(uint256 => SessionMetadata) public sessionMetadata;
    mapping(uint256 => mapping(address => UserPermission)) public sessionPermissions;
    mapping(address => uint256[]) public userManagedSessions;
    mapping(address => mapping(address => bool)) public delegatedAccess;

    uint256 public totalSessions;
    bool public paused;

    // ========== Events ==========

    event SessionMetadataUpdated(
        uint256 indexed sessionId,
        string name,
        string description
    );

    event PermissionGranted(
        uint256 indexed sessionId,
        address indexed grantee,
        PermissionLevel level,
        uint256 expiresAt
    );

    event PermissionRevoked(
        uint256 indexed sessionId,
        address indexed grantee
    );

    event DelegatedAccessGranted(
        address indexed owner,
        address indexed delegate
    );

    event DelegatedAccessRevoked(
        address indexed owner,
        address indexed delegate
    );

    event ManagerPaused(bool paused);

    // ========== Modifiers ==========

    modifier whenNotPaused() {
        require(!paused, "SessionManager: Paused");
        _;
    }

    modifier hasPermission(uint256 sessionId, PermissionLevel requiredLevel) {
        UserPermission memory perm = sessionPermissions[sessionId][msg.sender];
        require(perm.level >= requiredLevel, "SessionManager: Insufficient permissions");
        require(perm.expiresAt == 0 || block.timestamp <= perm.expiresAt, 
                "SessionManager: Permission expired");
        _;
    }

    // ========== Session Metadata ==========

    /**
     * @notice Register session metadata
     * @param sessionId Session ID
     * @param name Session name
     * @param description Session description
     * @param allowedTokens Array of token addresses to track
     */
    function registerSessionMetadata(
        uint256 sessionId,
        string calldata name,
        string calldata description,
        address[] calldata allowedTokens
    ) external whenNotPaused {
        require(bytes(name).length > 0, "SessionManager: Invalid name");

        sessionMetadata[sessionId] = SessionMetadata({
            name: name,
            description: description,
            allowedTokens: allowedTokens,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit SessionMetadataUpdated(sessionId, name, description);
    }

    /**
     * @notice Update session metadata
     * @param sessionId Session ID
     * @param name New session name
     * @param description New description
     */
    function updateSessionMetadata(
        uint256 sessionId,
        string calldata name,
        string calldata description
    ) external whenNotPaused {
        require(bytes(name).length > 0, "SessionManager: Invalid name");

        SessionMetadata storage metadata = sessionMetadata[sessionId];
        metadata.name = name;
        metadata.description = description;
        metadata.updatedAt = block.timestamp;

        emit SessionMetadataUpdated(sessionId, name, description);
    }

    /**
     * @notice Get session metadata
     * @param sessionId Session ID
     * @return Session metadata
     */
    function getSessionMetadata(uint256 sessionId) 
        external 
        view 
        returns (SessionMetadata memory) {
        return sessionMetadata[sessionId];
    }

    // ========== Permission Management ==========

    /**
     * @notice Grant permission to access session
     * @param sessionId Session ID
     * @param grantee Address to grant permission to
     * @param level Permission level
     * @param duration Duration in seconds (0 for permanent)
     */
    function grantPermission(
        uint256 sessionId,
        address grantee,
        PermissionLevel level,
        uint256 duration
    ) external whenNotPaused {
        require(grantee != address(0), "SessionManager: Invalid grantee");
        require(level != PermissionLevel.NONE, "SessionManager: Invalid level");

        uint256 expiresAt = duration > 0 ? block.timestamp + duration : 0;

        sessionPermissions[sessionId][grantee] = UserPermission({
            level: level,
            grantedAt: block.timestamp,
            expiresAt: expiresAt
        });

        emit PermissionGranted(sessionId, grantee, level, expiresAt);
    }

    /**
     * @notice Revoke permission for session
     * @param sessionId Session ID
     * @param grantee Address to revoke permission from
     */
    function revokePermission(uint256 sessionId, address grantee) 
        external 
        whenNotPaused {
        delete sessionPermissions[sessionId][grantee];
        emit PermissionRevoked(sessionId, grantee);
    }

    /**
     * @notice Check user permission level
     * @param sessionId Session ID
     * @param user User address
     * @return Permission level
     */
    function getUserPermissionLevel(uint256 sessionId, address user) 
        external 
        view 
        returns (PermissionLevel) {
        UserPermission memory perm = sessionPermissions[sessionId][user];
        
        // Check if permission is expired
        if (perm.expiresAt > 0 && block.timestamp > perm.expiresAt) {
            return PermissionLevel.NONE;
        }
        
        return perm.level;
    }

    /**
     * @notice Check if user has specific permission
     * @param sessionId Session ID
     * @param user User address
     * @param requiredLevel Required permission level
     * @return Whether user has permission
     */
    function hasPermissionLevel(
        uint256 sessionId,
        address user,
        PermissionLevel requiredLevel
    ) external view returns (bool) {
        UserPermission memory perm = sessionPermissions[sessionId][user];
        
        if (perm.expiresAt > 0 && block.timestamp > perm.expiresAt) {
            return false;
        }
        
        return perm.level >= requiredLevel;
    }

    // ========== Delegated Access ==========

    /**
     * @notice Grant delegated access to another address
     * @param delegate Address to delegate to
     */
    function grantDelegatedAccess(address delegate) external whenNotPaused {
        require(delegate != address(0), "SessionManager: Invalid delegate");
        require(delegate != msg.sender, "SessionManager: Cannot delegate to self");

        delegatedAccess[msg.sender][delegate] = true;
        emit DelegatedAccessGranted(msg.sender, delegate);
    }

    /**
     * @notice Revoke delegated access
     * @param delegate Address to revoke access from
     */
    function revokeDelegatedAccess(address delegate) external {
        delegatedAccess[msg.sender][delegate] = false;
        emit DelegatedAccessRevoked(msg.sender, delegate);
    }

    /**
     * @notice Check if delegate has access
     * @param owner Owner address
     * @param delegate Delegate address
     * @return Whether delegate has access
     */
    function hasDelegatedAccess(address owner, address delegate) 
        external 
        view 
        returns (bool) {
        return delegatedAccess[owner][delegate];
    }

    // ========== Admin Functions ==========

    /**
     * @notice Pause manager (owner only)
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit ManagerPaused(_paused);
    }

    /**
     * @notice Get total registered sessions
     * @return Total sessions
     */
    function getTotalSessions() external view returns (uint256) {
        return totalSessions;
    }
}
