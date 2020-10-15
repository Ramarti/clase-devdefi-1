// We require the Buidler Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `buidler run <script>` you'll find the Buidler
// Runtime Environment's members available in the global scope.
const bre = require("@nomiclabs/buidler")
const { concat } = require("ethers/lib/utils")
const ethers = bre.ethers

async function deploy(deposit, limitAttendees) {
  const KickBack = await ethers.getContractFactory("KickBack")
  const kickback = await KickBack.deploy(deposit, limitAttendees)

  await kickback.deployed()

  console.log("KickBack deployed to:", kickback.address)
  return kickback
}

async function main() {
  // Buidler always runs the compile task when running scripts through it. 
  // If this runs in a standalone fashion you may want to call compile manually 
  // to make sure everything is compiled
  // await bre.run('compile');

  // We get the contract to deploy
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    await deployer.getAddress()
  );
  
  const kickback = await deploy(ethers.utils.parseEther('0.5'), '10')
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });
