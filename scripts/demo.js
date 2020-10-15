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
  const kickback = await deploy(ethers.utils.parseEther('1'), '10')
  let dep = await kickback.deposit()
  console.log('deposit:', ethers.utils.formatEther(dep))
  let admin = await kickback.admin()
  console.log('admin', admin)

  const accounts = await ethers.getSigners();
  let owner = accounts[0]
  let attendant1 = accounts[1]
  let attendant2 = accounts[2]
  let beforeRegisterBalance = await attendant1.getBalance()
  console.log('beforeRegisterBalance', ethers.utils.formatEther(beforeRegisterBalance))
  let tx = await kickback.register({
    value: ethers.utils.parseEther('1')
  })
  console.log(tx)
  let afterRegisterBalance = await attendant1.getBalance()
  console.log('afterRegisterBalance', ethers.utils.formatEther(afterRegisterBalance))
  let kickback2 = kickback.connect(attendant2)
  let ownerKickBack = kickback.connect(owner)
  let tx2 = await kickback2.register({
    value: ethers.utils.parseEther('1')
  })
  console.log(tx2)

  console.log('started')
  await ownerKickBack.startEvent()
  let attendant1Wallet = await attendant1.getAddress()
  await ownerKickBack.markAttendance(attendant1Wallet)
  var state = await ownerKickBack.eventState()
  console.log('state', state.toString())
  var payout = await ownerKickBack.payoutAmount()
  console.log('payout', payout.toString())

  console.log('finalizing')
  await ownerKickBack.finalizeEvent()
  state = await ownerKickBack.eventState()
  console.log('state', state.toString())
  payout = await ownerKickBack.payoutAmount()
  console.log('payout', payout.toString())

  withdrawKickBack = ownerKickBack.connect(attendant1)
  let withdrawalTx = await withdrawKickBack.withdraw()
  let afterWithdrawnBalance = await attendant1.getBalance()
  console.log('afterWithdrawnBalance', ethers.utils.formatEther(afterWithdrawnBalance))
  
  console.log(withdrawalTx.value.toString())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  });
