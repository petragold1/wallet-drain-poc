require('dotenv').config();

let ethers;
try {
  ethers = require('ethers');
} catch (e) {
  console.error('Missing ethers. Run: npm install ethers');
  process.exit(1);
}

// normalize hex input
const hex = process.argv[2] || process.env.HEX;
if (!hex) {
  console.error('Usage: node decode-collect.js <hex>');
  process.exit(1);
}
const h = hex.startsWith('0x') ? hex : '0x' + hex;

// handle ethers v5 vs v6 differences
let abiCoder;
if (ethers.AbiCoder) {
  // ethers v6
  abiCoder = ethers.AbiCoder.defaultAbiCoder();
} else {
  // ethers v5
  abiCoder = ethers.utils.defaultAbiCoder;
}

try {
  const decoded = abiCoder.decode(['uint256','string'], h);
  console.log('Decoded collect() ->');
  console.log(' balance (wei):', decoded[0].toString());
  if (ethers.formatEther) {
    console.log(' balance (ETH) :', ethers.formatEther(decoded[0]));
  } else {
    console.log(' balance (ETH) :', ethers.utils.formatEther(decoded[0]));
  }
  console.log(' discord name  :', decoded[1]);
} catch (err) {
  console.error('Failed to decode as (uint256,string):', err.message);
}
