// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Mock ERC20 token for testing
 */
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/**
 * @title MockTarget
 * @notice Mock target contract for delegated calls
 */
contract MockTarget {
    event Executed(address indexed caller, uint256 amount, bytes data);

    fallback() external payable {
        emit Executed(msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Executed(msg.sender, msg.value, "");
    }

    function swap(address token, uint256 amount) external payable returns (bool) {
        emit Executed(msg.sender, amount, msg.data);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        emit Executed(msg.sender, amount, msg.data);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        emit Executed(msg.sender, amount, msg.data);
        return true;
    }
}

/**
 * @title MockVault
 * @notice Mock vault for testing subscription payments
 */
contract MockVault {
    mapping(address => uint256) public deposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function deposit(uint256 amount) external payable {
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        deposits[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return deposits[user];
    }
}

/**
 * @title MockUniswapRouter
 * @notice Mock Uniswap V3 router for testing trading
 */
contract MockUniswapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    mapping(address => uint256) public swapVolume;

    event SwapExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn);

    function exactInputSingle(ExactInputSingleParams calldata params) 
        external 
        payable 
        returns (uint256 amountOut) {
        swapVolume[msg.sender] += params.amountIn;
        emit SwapExecuted(msg.sender, params.tokenIn, params.tokenOut, params.amountIn);
        return params.amountIn * 99 / 100;
    }

    function getSwapVolume(address user) external view returns (uint256) {
        return swapVolume[user];
    }
}

/**
 * @title MockPaymentProcessor
 * @notice Mock payment processor for subscription testing
 */
contract MockPaymentProcessor {
    mapping(address => mapping(address => uint256)) public payments;
    mapping(address => uint256) public totalPaid;

    event PaymentProcessed(address indexed user, address indexed merchant, uint256 amount);

    function processPayment(address merchant, uint256 amount) external {
        payments[msg.sender][merchant] += amount;
        totalPaid[msg.sender] += amount;
        emit PaymentProcessed(msg.sender, merchant, amount);
    }

    function getPaymentHistory(address user, address merchant) 
        external 
        view 
        returns (uint256) {
        return payments[user][merchant];
    }

    function getTotalPaid(address user) external view returns (uint256) {
        return totalPaid[user];
    }
}

/**
 * @title MockNFT
 * @notice Mock NFT for gaming session testing
 */
contract MockNFT {
    mapping(uint256 => address) public owners;
    mapping(address => uint256[]) public balance;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {
        for (uint256 i = 0; i < 10; i++) {
            owners[i] = address(0xdeadbeef);
            balance[address(0xdeadbeef)].push(i);
        }
    }

    function transfer(address to, uint256 tokenId) external {
        require(owners[tokenId] == msg.sender, "Not owner");
        owners[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(owners[tokenId] == from, "Not owner");
        owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return owners[tokenId];
    }
}
