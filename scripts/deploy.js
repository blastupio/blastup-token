// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {

  // Get the contract owner
  const [deployer] = await ethers.getSigners();
  const mintingAddress = process.env.INIT_DAO_WALLET;
  
  console.log(`Deploying contract from: ${deployer.address}`);

  // Hardhat helper to get the ethers contractFactory object
  const BLPToken = await ethers.getContractFactory('BLPToken');

  // Deploy the contract
  console.log('Deploying BlastUP Token $BLP...');

  const blpToken = await BLPToken.deploy(mintingAddress);
  await blpToken.waitForDeployment();

  const contractAddress = await blpToken.getAddress();
  console.log(`BlastUp Token deployed to: ${contractAddress}`)
  
  const args = [
    mintingAddress,
  ]

  await hre.run(`verify:verify`, {
    address: contractAddress,
    constructorArguments: args
})
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });