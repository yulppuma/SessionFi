export const SESSION_FI_ABI = [
  {
    inputs: [
      { name: "sessionKey", type: "address" },
      { name: "target", type: "address" },
      { name: "selector", type: "bytes4" },
      { name: "token", type: "address" },
      { name: "maxAmount", type: "uint256" },
      { name: "duration", type: "uint256" },
      { name: "maxNonce", type: "uint256" }
    ],
    name: "createSession",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { name: "sessionId", type: "uint256" },
      { name: "target", type: "address" },
      { name: "data", type: "bytes" },
      { name: "amount", type: "uint256" }
    ],
    name: "executeSessionTransaction",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [{ name: "sessionId", type: "uint256" }],
    name: "getSession",
    outputs: [{
      components: [
        { name: "owner", type: "address" },
        { name: "sessionKey", type: "address" },
        { name: "allowedTarget", type: "address" },
        { name: "allowedSelector", type: "bytes4" },
        { name: "allowedToken", type: "address" },
        { name: "maxAmount", type: "uint256" },
        { name: "spentAmount", type: "uint256" },
        { name: "expiry", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "maxNonce", type: "uint256" },
        { name: "active", type: "bool" },
        { name: "createdAt", type: "uint256" }
      ],
      name: "",
      type: "tuple"
    }],
    stateMutability: "view",
    type: "function"
  }
]

export const CONTRACTS = {
  sessionFi: import.meta.env.VITE_SESSION_FI_CONTRACT || '',
  sessionManager: import.meta.env.VITE_SESSION_MANAGER_CONTRACT || '',
}