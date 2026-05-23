// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SessionFiWallet} from "../src/SessionFiWallet.sol";
import {MockERC20} from "./mocks/MockContracts.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Simple mock that just accepts calls
contract SimpleCallTarget {
    fallback() external payable {
        // Just accept the call
    }
    receive() external payable {}
}

// ========== REAL CONTRACT INTERFACES FOR INTEGRATION TESTS ==========

/// @notice Uniswap V3 SwapRouter interface (REAL)
interface ISwapRouter {
    struct ExactInputSingleParams {
        bytes4 tokenIn;
        bytes4 tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

/// @notice OpenZeppelin IERC20 (REAL - already imported)
// IERC20 is already imported above

contract SessionFiWalletTest is Test {
    SessionFiWallet public sessionFi;
    MockERC20 public usdc;
    MockERC20 public dai;
    SimpleCallTarget public target;
    SimpleCallTarget public uniswapRouter;
    SimpleCallTarget public paymentProcessor;

    address public owner = address(0x1);
    address public user = address(0x2);
    address public sessionKey = address(0x3);
    address public merchant = address(0x4);
    address public attacker = address(0x5);

    uint256 public constant INITIAL_USDC_BALANCE = 1000e6;
    uint256 public constant INITIAL_DAI_BALANCE = 1000e18;
    uint256 public constant INITIAL_ETH = 10 ether;

    // Function selectors
    bytes4 public constant SWAP_SELECTOR = bytes4(keccak256("swap(address,uint256)"));
    bytes4 public constant TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 public constant PROCESS_PAYMENT_SELECTOR = 
        bytes4(keccak256("processPayment(uint256)"));

    function setUp() public {
        vm.startPrank(owner);
        sessionFi = new SessionFiWallet();
        usdc = new MockERC20("USDC", "USDC");
        dai = new MockERC20("DAI", "DAI");
        target = new SimpleCallTarget();
        uniswapRouter = new SimpleCallTarget();
        paymentProcessor = new SimpleCallTarget();
        vm.stopPrank();

        // Setup balances
        usdc.mint(user, INITIAL_USDC_BALANCE);
        dai.mint(user, INITIAL_DAI_BALANCE);
        vm.deal(user, INITIAL_ETH);
        vm.deal(sessionKey, INITIAL_ETH);
        vm.deal(merchant, 1 ether);
    }

    // ========== UNIT TESTS ==========

    function test_CreateETHSession() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(0),  // ETH
            1 ether,
            1 hours,
            10
        );

        assertEq(sessionId, 0);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.owner, user);
        assertEq(session.sessionKey, sessionKey);
        assertEq(session.allowedTarget, address(target));
        assertEq(session.allowedToken, address(0));
        assertEq(session.maxAmount, 1 ether);
        assertTrue(session.active);
    }

    function test_ExecuteETHTransfer() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(0),  // ETH
            1 ether,
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, user, 100);

        vm.prank(sessionKey);
        bool success = sessionFi.executeSessionTransaction{value: 0.5 ether}(
            sessionId,
            address(target),
            callData,
            0.5 ether
        );

        assertTrue(success);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, 0.5 ether);
        assertEq(session.nonce, 1);
    }

    function test_RejectETHWithWrongValue() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(0),  // ETH
            1 ether,
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, user, 100);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: ETH value mismatch");
        sessionFi.executeSessionTransaction{value: 0.5 ether}(
            sessionId,
            address(target),
            callData,
            0.3 ether  // Mismatch!
        );
    }

    function test_ETHSpendLimitEnforced() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(0),  // ETH
            0.5 ether,   // Only 0.5 ETH allowed
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, user, 100);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Spend limit exceeded");
        sessionFi.executeSessionTransaction{value: 1 ether}(
            sessionId,
            address(target),
            callData,
            1 ether  // Exceeds limit
        );
    }

    // ========== ERC20 TOKEN TRANSFER TESTS ==========

    function test_CreateERC20Session() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),  // USDC
            100e6,          // 100 USDC max
            1 hours,
            10
        );

        assertEq(sessionId, 0);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.allowedToken, address(usdc));
        assertEq(session.maxAmount, 100e6);
    }

    function test_ExecuteERC20Transfer() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(sessionKey);
        bool success = sessionFi.executeSessionTransaction(
            sessionId,
            address(uniswapRouter),
            callData,
            50e6  // 50 USDC
        );

        assertTrue(success);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, 50e6);
        assertEq(session.nonce, 1);
    }

    function test_RejectERC20WithETHValue() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: ERC20 sessions should not send ETH");
        sessionFi.executeSessionTransaction{value: 0.1 ether}(
            sessionId,
            address(uniswapRouter),
            callData,
            50e6
        );
    }

    function test_ERC20SpendLimitEnforced() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            50e6,  // Only 50 USDC allowed
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 60e6);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Spend limit exceeded");
        sessionFi.executeSessionTransaction(
            sessionId,
            address(uniswapRouter),
            callData,
            60e6  // Exceeds 50e6 limit
        );
    }

    // ========== MULTI-TOKEN SCENARIOS ==========

    function test_MultipleERC20Sessions() public {
        vm.prank(user);
        uint256 usdcSessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        vm.prank(user);
        uint256 daiSessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(dai),
            1000e18,
            1 hours,
            10
        );

        assertEq(usdcSessionId, 0);
        assertEq(daiSessionId, 1);

        SessionFiWallet.Session memory usdcSession = sessionFi.getSession(usdcSessionId);
        SessionFiWallet.Session memory daiSession = sessionFi.getSession(daiSessionId);

        assertEq(usdcSession.allowedToken, address(usdc));
        assertEq(daiSession.allowedToken, address(dai));
    }

    // ========== REAL-WORLD USE CASE: AI TRADING AGENT ==========

    function test_AITradingAgent_SingleSwap() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            50e6,
            1 days,
            5
        );

        bytes memory swapData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 20e6);

        vm.prank(sessionKey);
        bool success = sessionFi.executeSessionTransaction(
            sessionId,
            address(uniswapRouter),
            swapData,
            20e6
        );

        assertTrue(success);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, 20e6);
        assertEq(session.nonce, 1);
        assertEq(sessionFi.getExecutionCount(sessionId), 1);
    }

    function test_AITradingAgent_MultipleSwaps() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 days,
            10
        );

        // First swap: 25 USDC
        bytes memory swap1 = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 25e6);
        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(uniswapRouter), swap1, 25e6);

        // Second swap: 30 USDC
        bytes memory swap2 = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 30e6);
        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(uniswapRouter), swap2, 30e6);

        // Third swap: 40 USDC
        bytes memory swap3 = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 40e6);
        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(uniswapRouter), swap3, 40e6);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, 95e6);
        assertEq(session.nonce, 3);
        assertEq(sessionFi.getExecutionCount(sessionId), 3);
    }

    function test_AITradingAgent_ExceedsSpendLimit() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            50e6,
            1 days,
            10
        );

        // First swap: 30 USDC
        bytes memory swap1 = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 30e6);
        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(uniswapRouter), swap1, 30e6);

        // Second swap: 25 USDC (would exceed)
        bytes memory swap2 = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 25e6);
        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Spend limit exceeded");
        sessionFi.executeSessionTransaction(sessionId, address(uniswapRouter), swap2, 25e6);
    }

    // ========== REAL-WORLD USE CASE: SUBSCRIPTION PAYMENTS ==========

    function test_SubscriptionPayment_SinglePayment() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            merchant,
            address(paymentProcessor),
            PROCESS_PAYMENT_SELECTOR,
            address(usdc),
            120e6,
            365 days,
            12
        );

        bytes memory paymentData = abi.encodeWithSelector(PROCESS_PAYMENT_SELECTOR, 10e6);

        vm.prank(merchant);
        bool success = sessionFi.executeSessionTransaction(
            sessionId,
            address(paymentProcessor),
            paymentData,
            10e6
        );

        assertTrue(success);

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, 10e6);
    }

    function test_SubscriptionPayment_MonthlyCharges() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            merchant,
            address(paymentProcessor),
            PROCESS_PAYMENT_SELECTOR,
            address(usdc),
            100e6,
            365 days,
            12
        );

        // Process 10 monthly charges of 10 USDC each
        for (uint256 i = 0; i < 10; i++) {
            bytes memory paymentData = abi.encodeWithSelector(PROCESS_PAYMENT_SELECTOR, 10e6);
            vm.prank(merchant);
            sessionFi.executeSessionTransaction(
                sessionId,
                address(paymentProcessor),
                paymentData,
                10e6
            );
        }

        SessionFiWallet.Session memory session = sessionFi.getSession(sessionId);
        assertEq(session.spentAmount, 100e6);
        assertEq(session.nonce, 10);
    }

    function test_SubscriptionPayment_ExceedsMonthlyBudget() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            merchant,
            address(paymentProcessor),
            PROCESS_PAYMENT_SELECTOR,
            address(usdc),
            50e6,  // Only 50 USDC total
            365 days,
            12
        );

        // First 3 charges: 10 USDC each = 30 USDC
        for (uint256 i = 0; i < 3; i++) {
            bytes memory paymentData = abi.encodeWithSelector(PROCESS_PAYMENT_SELECTOR, 10e6);
            vm.prank(merchant);
            sessionFi.executeSessionTransaction(sessionId, address(paymentProcessor), paymentData, 10e6);
        }

        // Fourth charge would exceed budget (30 + 20 = 50, but 30 + 10 = 40 which is < 50)
        // So we try 25 USDC which would be 30 + 25 = 55 > 50
        bytes memory exceedPaymentData = abi.encodeWithSelector(PROCESS_PAYMENT_SELECTOR, 25e6);
        vm.prank(merchant);
        vm.expectRevert("SessionFi: Spend limit exceeded");
        sessionFi.executeSessionTransaction(sessionId, address(paymentProcessor), exceedPaymentData, 25e6);
    }

    // ========== SECURITY TESTS ==========

    function test_UnauthorizedCaller() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(attacker);
        vm.expectRevert("SessionFi: Not authorized");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }

    function test_WrongTargetContract() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Unapproved target");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }

    function test_WrongFunctionSelector() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(uniswapRouter),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        // Try to call with wrong selector
        bytes4 wrongSelector = bytes4(keccak256("transfer(address,uint256)"));
        bytes memory callData = abi.encodeWithSelector(wrongSelector, address(usdc), 50e6);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Unapproved function");
        sessionFi.executeSessionTransaction(sessionId, address(uniswapRouter), callData, 50e6);
    }

    function test_ExpiredSession() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        // Fast forward past expiration
        vm.warp(block.timestamp + 2 hours);

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Session expired");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }

    function test_MaxNonceExceeded() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            1000e6,
            1 days,
            2  // Only 2 transactions allowed
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        // Execute twice (allowed)
        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);

        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);

        // Third execution should fail
        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Max transactions exceeded");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }

    function test_RevokeSession() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey,
            address(target),
            SWAP_SELECTOR,
            address(usdc),
            100e6,
            1 hours,
            10
        );

        vm.prank(user);
        sessionFi.revokeSession(sessionId);

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(sessionKey);
        vm.expectRevert("SessionFi: Session not active");
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);
    }

    // ========== VIEW FUNCTION TESTS ==========

    function test_GetUserSessions() public {
        vm.prank(user);
        uint256 sessionId1 = sessionFi.createSession(
            sessionKey, address(target), SWAP_SELECTOR, address(usdc), 100e6, 1 hours, 10
        );

        vm.prank(user);
        uint256 sessionId2 = sessionFi.createSession(
            sessionKey, address(target), SWAP_SELECTOR, address(dai), 1000e18, 1 hours, 10
        );

        uint256[] memory userSessions = sessionFi.getUserSessions(user);
        assertEq(userSessions.length, 2);
        assertEq(userSessions[0], sessionId1);
        assertEq(userSessions[1], sessionId2);
    }

    function test_GetSpendingPercentage() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey, address(target), SWAP_SELECTOR, address(usdc), 100e6, 1 hours, 10
        );

        bytes memory callData = abi.encodeWithSelector(SWAP_SELECTOR, address(usdc), 50e6);

        vm.prank(sessionKey);
        sessionFi.executeSessionTransaction(sessionId, address(target), callData, 50e6);

        uint256 percentage = sessionFi.getSpendingPercentage(sessionId);
        assertEq(percentage, 50); // 50%
    }

    function test_GetSessionTimeRemaining() public {
        vm.prank(user);
        uint256 sessionId = sessionFi.createSession(
            sessionKey, address(target), SWAP_SELECTOR, address(usdc), 100e6, 1 hours, 10
        );

        uint256 timeRemaining = sessionFi.getSessionTimeRemaining(sessionId);
        assertGt(timeRemaining, 0);
        assertLe(timeRemaining, 1 hours);
    }
}
