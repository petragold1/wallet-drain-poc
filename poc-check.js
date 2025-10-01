require('dotenv').config();

const RPC = process.env.RPC_URL;
const TRAP = process.env.TRAP_ADDRESS;

if (!RPC || !TRAP) {
  console.error("Missing RPC_URL or TRAP_ADDRESS in .env — edit .env and try again.");
  process.exit(1);
}

// load ethers (works with v5 or v6)
let ethers;
try {
  ethers = require('ethers');
} catch (e) {
  console.error("Please run: npm install ethers");
  process.exit(1);
}

// helper to create provider (compatible with v5 & v6)
function makeProvider(rpcUrl) {
  if (ethers.JsonRpcProvider) {
    return new ethers.JsonRpcProvider(rpcUrl); // v6
  }
  if (ethers.providers && ethers.providers.JsonRpcProvider) {
    return new ethers.providers.JsonRpcProvider(rpcUrl); // v5
  }
  throw new Error("Unsupported ethers version. Install ethers v5 or v6.");
}

// ABI with collect() and shouldRespond()
const ABI = [
  {
    "inputs": [],
    "name": "collect",
    "outputs": [
      { "internalType": "uint256", "name": "balance", "type": "uint256" },
      { "internalType": "string", "name": "tag", "type": "string" }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{ "internalType": "bytes[]", "name": "data", "type": "bytes[]" }],
    "name": "shouldRespond",
    "outputs": [
      { "internalType": "bool", "name": "", "type": "bool" },
      { "internalType": "bytes", "name": "", "type": "bytes" }
    ],
    "stateMutability": "pure",
    "type": "function"
  }
];

async function main() {
  const provider = makeProvider(RPC);
  console.log("RPC:", RPC);
  console.log("Trap:", TRAP);

  const contract = new ethers.Contract(TRAP, ABI, provider);

  // 1. check bytecode
  try {
    const code = await provider.getCode(TRAP);
    if (!code || code === "0x") {
      console.error("No contract deployed at", TRAP);
      process.exit(2);
    } else {
      const byteLen = (code.length - 2) / 2;
      console.log("Contract found — bytecode size:", byteLen, "bytes");
    }
  } catch (err) {
    console.error("Failed to fetch contract code:", err.message || err);
    process.exit(3);
  }

  // 2. call collect()
  try {
    const result = await contract.collect();
    console.log("collect() raw result:", result);

    // ethers v6 returns object with named fields
    if (result.balance && result.tag) {
      console.log("Decoded balance:", result.balance.toString());
      console.log("Decoded tag:", result.tag);
    }
    // ethers v5 returns array
    else if (Array.isArray(result)) {
      console.log("Decoded balance:", result[0].toString());
      console.log("Decoded tag:", result[1]);
    }
  } catch (err) {
    console.error("Error calling collect():", err.message || err);
  }
}

main().catch(e => {
  console.error("Fatal error:", e);
  process.exit(99);
});
