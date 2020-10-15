const { expect } = require("chai");
const { ethers } = require("ethers");

async function deploy(deposit, limitAttendees) {
  console.log(ethers)
  const KickBack = await ethers.getContractFactory("KickBack")
  const kickback = await KickBack.deploy(deposit, limitAttendees)

  await kickback.deployed()

  console.log("KickBack deployed to:", kickback.address)
  return kickback
}

describe("KickBack", function() {
  it("Should register 2 attendants, 1 assistant, correctly split pot", async function() {
    const kickback = await deploy(ethers.utils.parseEther('1'), '10')
    
    let admin = await kickback.admin()
    console.log('admin', admin)

    const accounts = await ethers.getSigners();
    let owner = accounts[0]
    let attendant1 = accounts[1]
    let attendant2 = accounts[2]
    let beforeRegisterBalance = await attendant1.getBalance()
    expect(await kickback.connect(attendant1).register({
      value: ethers.utils.parseEther('1')
    })).to.changeBalance(attendant1, ethers.utils.parseEther('-1'))
    console.log(await kickback.participants(await attendant1.getAddress()))
    console.log(await attendant1.getAddress())


    
    expect(await kickback.connect(attendant2).register({
      value: ethers.utils.parseEther('1')
    })).to.changeBalance(attendant2, ethers.utils.parseEther('-1'))
    console.log(await kickback.participants(await attendant2.getAddress()))
    console.log(await attendant2.getAddress())


    console.log('started')
    await kickback.startEvent()
    await kickback.markAttendance(await attendant1.getAddress())
    var state = await kickback.eventState()
    console.log('state', kickback.toString())
    expect(state).to.equal(3)
    var payout = await kickback.payoutAmount()
    console.log('payout', payout.toString())
    expect(payout).to.equal(ethers.utils.parseEther(2))

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

  });
});
