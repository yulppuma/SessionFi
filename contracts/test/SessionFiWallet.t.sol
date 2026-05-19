// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SessionFiWallet} from "../../src/SessionFiWallet.sol";
import {MockERC20} from "./mocks/MockContracts.sol";
import {MockTarget} from "./mocks/MockContracts.sol";

contract SessionFiWalletTest is Test {
    SessionFiWallet public sessionFi;
    MockERC20 public usdc;
    MockTarget public target;

    address public owner = address(0x1);
    address public user = address(0x2);
    address public sessionKey = address(0x3);
    address public attacker = address(0x4);

    uint256 public constant INITIAL_BALANCE = 1000e6;
    uint256 public constant MAX_SPEND = 100e6;
    uint256 public constant DURATION = 1 hours;
    uint256 public constant MAX_NONCE = 10;

    bytes4 public constant SWAP_SELECTOR = 0x12345678;

    function setUp() public {
        vm.startPrank(owner);
        sessionFi = new SessionFiWallet();
        usdc = new MockERC20("USDC", "USDC");
        target = new MockTarget();
        vm.stopPrank();

        usdc.mint(user, INITIAL_BALANCE);

        vm.prank(user);
        usdc.approve(address(sessionFi), type(uint256).max);
    }

    function test_CreateSession() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            MAX_SPEND,
            DURATION,
            MAX_NONCE
        );

        assertEq(sessionId, 0);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.owner, user);
        assertEq(session.sessionKey, sessionKey);
        assertEq(session.allowedTarget, address(target));
        assertTrue(session.active);
    }

    function test_CreateSession_InvalidSessionKey() public {
        vm.prank(user);
        vm.expectRevert("SessionFi: Invalid session key");
        sessionFi.createSession(
            address(0),
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            MAX_SPEND,
            DURATION,
            MAX_NONCE
        );
    }

    function test_ExecuteSessionTransaction() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey, address(target), SWAP_SELECTOR, address(usdc), MAX_SPEND, DURATION, MAX_NONCE
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, user, 50e6);

        vm.prank(sessionKey);
        bool success = sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);

        assertTrue(success);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, 50e6);
        assertEq(session.nonce, 1);
    }

    function test_RevokeSession() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey, address(target), SWAP_SELECTOR, address(usdc), MAX_SPEND, DURATION, MAX_NONCE
        );

        vm.prank(user);
        sessionFi.revokeSession(sessionId);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertFalse(session.active);
    }

    function test_IsSessionValid() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey, address(target), SWAP_SELECTOR, address(usdc), MAX_SPEND, DURATION, MAX_NONCE
        );

        assertTrue(sessionFi.isSessionValid(sessionId));
    }
}
