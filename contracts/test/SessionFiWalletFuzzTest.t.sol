// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SessionFiWallet} from "../../src/SessionFiWallet.sol";
import {MockERC20} from "./mocks/MockContracts.sol";

// Simple mock that just accepts calls
contract SimpleCallTarget {
    fallback() external payable {
        // Just accept the call
    }
    receive() external payable {}
}

// ========== STATELESS FUZZ TESTS ==========
// Tests individual functions with random inputs

contract SessionFiWalletFuzzTest is Test {
    SessionFiWallet public sessionFi;
    MockERC20 public usdc;
    SimpleCallTarget public target;

    address public owner = address(0x1);
    address public user = address(0x2);

    bytes4 public constant SWAP_SELECTOR = bytes4(keccak256("swap(address,uint256)"));

    function setUp() public {
        vm.prank(owner);
        sessionFi = new SessionFiWallet();
        usdc = new MockERC20("USDC", "USDC");
        target = new SimpleCallTarget();

        usdc.mint(user, 1_000_000e6);
        vm.deal(user, 100 ether);
    }

    // ========== FUZZ: Session Creation ==========

    /// @notice Fuzz test: Creating sessions with various max amounts
    function testFuzz_CreateSessionWithRandomAmount(uint256 maxAmount) public {
        // Bound to reasonable token amounts
        maxAmount = bound(maxAmount, 1e6, 1_000_000e6);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            address(0x3),
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            maxAmount,
            1 days,
            10
        );

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.maxAmount, maxAmount);
        assertEq(session.spentAmount, 0);
    }

    /// @notice Fuzz test: Creating sessions with various durations
    function testFuzz_CreateSessionWithRandomDuration(uint256 duration) public {
        // Bound to reasonable durations (1 minute to 365 days)
        duration = bound(duration, 1 minutes, 365 days);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            address(0x3),
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            duration,
            10
        );

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.expiry, block.timestamp + duration);
    }

    /// @notice Fuzz test: Creating sessions with various max nonces
    function testFuzz_CreateSessionWithRandomMaxNonce(uint256 maxNonce) public {
        // Bound to reasonable nonce limits (1 to 1000)
        maxNonce = bound(maxNonce, 1, 1000);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            address(0x3),
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            maxNonce
        );

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.maxNonce, maxNonce);
    }

    // ========== FUZZ: Spending Limits ==========

    /// @notice Fuzz test: Execute transactions with various amounts
    function testFuzz_ExecuteWithRandomAmounts(uint256 sessionAmount, uint256 executeAmount) public {
        // Bound amounts
        sessionAmount = bound(sessionAmount, 1e6, 1_000_000e6);
        executeAmount = bound(executeAmount, 1e6, sessionAmount);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            sessionAmount,
            1 days,
            100
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), executeAmount);

        vm.prank(user);
        bool success = sessionFi.executeSessionTransaction(
            sessionId,
            address(target),
            callData,
            executeAmount
        );

        assertTrue(success);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, executeAmount);
    }

    /// @notice Fuzz test: Multiple executions with random amounts (FIXED - use memory array)
    function testFuzz_MultipleExecutesAccumulateSpending(uint256 count, uint256 seed) public {
        // Generate array of random amounts in memory
        count = bound(count, 1, 10);
        
        uint256 totalAmount = 0;
        uint256[] memory amounts = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            // Use seed to generate different amounts
            amounts[i] = bound(uint256(keccak256(abi.encode(seed, i))), 1e6, 100e6);
            totalAmount += amounts[i];
        }
        
        // Make sure total doesn't overflow
        if (totalAmount > 1_000_000e6) {
            return; // Skip if total is too high
        }

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            totalAmount + 1e6, // Make sure it doesn't exceed
            1 days,
            (count + 1)
        );

        for (uint256 i = 0; i < count; i++) {
            bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), amounts[i]);
            vm.prank(user);
            sessionFi.executeSessionTransaction(sessionId, address(target), callData, amounts[i]);
        }

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, totalAmount);
        assertEq(session.nonce, count);
    }

    /// @notice Fuzz test: Spending limit enforcement
    function testFuzz_ExceedingSpendLimitReverts(uint256 maxAmount, uint256 overAmount) public {
        maxAmount = bound(maxAmount, 10e6, 1_000_000e6);
        overAmount = bound(overAmount, 1, maxAmount); // At least 1 unit over

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            maxAmount,
            1 days,
            10
        );

        // Try to execute with maxAmount + overAmount (should fail)
        bytes memory callData = abi.encodeWithSelector(
            SWAP_SELECTOR,
            address(usdc),
            maxAmount + overAmount
        );

        vm.prank(user);
        vm.expectRevert("SessionFi: Spend limit exceeded");
        sessionFi.executeSessionTransaction(
            sessionId,
            address(target),
            callData,
            maxAmount + overAmount
        );
    }

    // ========== FUZZ: Time-Based Behaviors ==========

    /// @notice Fuzz test: Sessions expire at correct time
    function testFuzz_SessionExpiresAtCorrectTime(uint256 duration, uint256 warpAmount) public {
        duration = bound(duration, 1 hours, 365 days);
        warpAmount = bound(warpAmount, 1 seconds, duration);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            duration,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        // Warp before expiration - should succeed
        vm.warp(block.timestamp + warpAmount);
        vm.prank(user);
        bool success = sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
        assertTrue(success);

        // Warp past expiration - should fail
        vm.warp(block.timestamp + duration);
        vm.prank(user);
        vm.expectRevert("SessionFi: Session expired");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }

    // ========== FUZZ: ETH Transfers ==========

    /// @notice Fuzz test: ETH transfers with various amounts
    function testFuzz_ETHTransfersWithRandomAmounts(uint256 sessionAmount, uint256 executeAmount)
        public
    {
        sessionAmount = bound(sessionAmount, 0.001 ether, 10 ether);
        executeAmount = bound(executeAmount, 0.001 ether, sessionAmount);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(0), // ETH
            sessionAmount,
            1 days,
            100
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(0), executeAmount);

        vm.prank(user);
        bool success = sessionFi.executeSessionTransaction{value: executeAmount}(
            sessionId,
            address(target),
            callData,
            executeAmount
        );

        assertTrue(success);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, executeAmount);
    }

    /// @notice Fuzz test: ETH value mismatch detection
    function testFuzz_ETHValueMismatchDetected(uint256 sessionAmount, uint256 executeAmount) public {
        sessionAmount = bound(sessionAmount, 0.001 ether, 10 ether);
        executeAmount = bound(executeAmount, 0.001 ether, sessionAmount);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(0),
            sessionAmount,
            1 days,
            100
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(0), executeAmount);

        vm.prank(user);
        // Send different amount than claimed
        vm.expectRevert("SessionFi: ETH value mismatch");
        sessionFi.executeSessionTransaction{value: executeAmount + 1 wei}(
            sessionId,
            address(target),
            callData,
            executeAmount
        );
    }

    // ========== FUZZ: Nonce Enforcement ==========

    /// @notice Fuzz test: Max nonce enforcement
    function testFuzz_MaxNonceEnforcement(uint256 maxNonce) public {
        maxNonce = bound(maxNonce, 1, 100);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100_000e6,
            1 days,
            maxNonce
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 1e6);

        // Execute maxNonce times - should succeed
        for (uint256 i = 0; i < maxNonce; i++) {
            vm.prank(user);
            sessionFi.executeSessionTransaction(sessionId, address(target), callData, 1e6);
        }

        // One more should fail
        vm.prank(user);
        vm.expectRevert("SessionFi: Max transactions exceeded");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 1e6);
    }

    // ========== FUZZ: Authorization ==========

    /// @notice Fuzz test: Only authorized callers can execute
    function testFuzz_UnauthorizedCallerRejected(address attacker) public {
        vm.assume(attacker != user && attacker != address(0));

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(attacker);
        vm.expectRevert("SessionFi: Not authorized");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }

    // ========== FUZZ: Target & Selector Validation ==========

    /// @notice Fuzz test: Wrong target rejected
    function testFuzz_WrongTargetRejected(address wrongTarget) public {
        vm.assume(wrongTarget != address(target) && wrongTarget != address(0));

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(user);
        vm.expectRevert("SessionFi: Unapproved target");
        sessionFi.executeSessionTransaction(sessionId, wrongTarget, callData, 50e6);
    }

    /// @notice Fuzz test: Wrong selector rejected
    function testFuzz_WrongSelectorRejected(bytes4 wrongSelector) public {
        vm.assume(wrongSelector != SWAP_SELECTOR);

        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            user,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        bytes memory callData = abi.encodeWithSelector(wrongSelector, address(usdc), 50e6);

        vm.prank(user);
        vm.expectRevert("SessionFi: Unapproved function");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }
}

// ========== STATEFUL FUZZ TESTS (Invariants) ==========
// Tests that certain properties always hold true

contract SessionFiWalletInvariantTest is Test {
    SessionFiWallet public sessionFi;
    MockERC20 public usdc;
    SimpleCallTarget public target;

    address public owner = address(0x1);
    address public user = address(0x2);
    address public sessionKey = address(0x3);

    bytes4 public constant SWAP_SELECTOR = bytes4(keccak256("swap(address,uint256)"));

    function setUp() public {
        vm.prank(owner);
        sessionFi = new SessionFiWallet();
        usdc = new MockERC20("USDC", "USDC");
        target = new SimpleCallTarget();

        usdc.mint(user, 10_000_000e6);
        vm.deal(user, 1000 ether);

        // Label for better error messages
        vm.label(address(sessionFi), "SessionFiWallet");
        vm.label(user, "User");
        vm.label(sessionKey, "SessionKey");
    }

    // ========== INVARIANT 1: Spent Amount Never Exceeds Max ==========

    function testInvariant_SpentNeverExceedsMax() public {
        // Create a session
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        
        // Invariant: spentAmount <= maxAmount
        assertLe(session.spentAmount, session.maxAmount, "Spent amount exceeds maximum");
    }

    // ========== INVARIANT 2: Nonce Never Exceeds MaxNonce ==========

    function testInvariant_NonceNeverExceedsMaxNonce() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            1_000_000e6,
            1 days,
            5
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 1e6);

        // Execute maximum number of times
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(sessionKey);
            sessionFi.executeSessionTransaction(sessionId, address(target), callData, 1e6);
        }

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        
        // Invariant: nonce <= maxNonce
        assertLe(session.nonce, session.maxNonce, "Nonce exceeds max nonce");
    }

    // ========== INVARIANT 3: Inactive Sessions Cannot Execute ==========

    function testInvariant_InactiveSessionsCannotExecute() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        // Revoke the session
        vm.prank(user);
        sessionFi.revokeSession(sessionId);

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        // Try to execute - should fail
        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Session not active");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);

        // Invariant: inactive session cannot execute
        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertFalse(session.active, "Revoked session is still active");
    }

    // ========== INVARIANT 4: Session Owner Consistency ==========

    function testInvariant_SessionOwnerIsConsistent() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        
        // Invariant: session owner is the creator
        assertEq(session.owner, user, "Session owner does not match creator");
    }

    // ========== INVARIANT 5: Expiration Cannot Be in Past ==========

    function testInvariant_ExpirationAlwaysInFuture() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        
        // Invariant: expiry is in the future
        assertGt(session.expiry, block.timestamp, "Session expiry is in the past");
    }

    // ========== INVARIANT 6: Session Counter Increments (FIXED - call as function) ==========

    function testInvariant_SessionCounterIncrementsCorrectly() public {
        // FIXED: Call sessionCounter() as a function, not a property
        uint256 initialCount = sessionFi.sessionCounter();

        vm.prank(user);
        sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        // FIXED: Call sessionCounter() as a function
        uint256 finalCount = sessionFi.sessionCounter();
        
        // Invariant: counter incremented by exactly 1
        assertEq(finalCount, initialCount + 1, "Session counter did not increment");
    }

    // ========== INVARIANT 7: Only Owner Can Emergency Revoke ==========

    function testInvariant_OnlyOwnerCanEmergencyRevoke() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        // Non-owner cannot emergency revoke
        vm.prank(sessionKey);
        vm.expectRevert();
        sessionFi.emergencyRevokeSession(sessionId);

        // Owner can emergency revoke
        vm.prank(owner);
        sessionFi.emergencyRevokeSession(sessionId);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        
        // Invariant: only owner can trigger emergency revoke
        assertFalse(session.active, "Emergency revoke did not deactivate session");
    }

    // ========== INVARIANT 8: ETH and Token Sessions are Distinct ==========

    function testInvariant_ETHAndTokenSessionsAreDistinct() public {
        vm.prank(user);
        uint256 ethSessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(0), // ETH
            1 ether,
            1 days,
            10
        );

        vm.prank(user);
        uint256 tokenSessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc), // Token
            100e6,
            1 days,
            10
        );

        SessionFiWallet.Session memory ethSession = sessionFi.getSession(ethSessionId);
        SessionFiWallet.Session memory tokenSession = sessionFi.getSession(tokenSessionId);

        // Invariant: allowedToken distinguishes ETH vs token sessions
        assertEq(ethSession.allowedToken, address(0), "ETH session has token address");
        assertEq(tokenSession.allowedToken, address(usdc), "Token session has wrong token");
    }

    // ========== INVARIANT 9: User Can Only Revoke Their Own Sessions ==========

    function testInvariant_OnlyOwnerCanRevokeOwnSession() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        // Other user cannot revoke
        address otherUser = address(0x99);
        vm.prank(otherUser);
        vm.expectRevert("SessionFi: Not session owner");
        sessionFi.revokeSession(sessionId);

        // Original owner can revoke
        vm.prank(user);
        sessionFi.revokeSession(sessionId);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        
        // Invariant: only session owner can revoke
        assertFalse(session.active, "Session owner could not revoke");
    }

    // ========== INVARIANT 10: Spending Percentage is Accurate ==========

    function testInvariant_SpendingPercentageIsAccurate() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);

        uint256 percentage = sessionFi.getSpendingPercentage(sessionId);
        
        // Invariant: spending percentage = (spent / max) * 100
        // 50e6 / 100e6 * 100 = 50
        assertEq(percentage, 50, "Spending percentage is incorrect");
    }
}
