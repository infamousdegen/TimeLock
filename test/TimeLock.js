const { ethers } = require("hardhat");
const { expect } = require("chai");





describe("TokenDeployment", async function () {

  before("SettingUp", async function () {
    //setting up the environment
    let [owner, addr1, addr2, addr3] = await ethers.getSigners();

    const TimeLockFactory = await ethers.getContractFactory("TimeLock", owner);
    this.TimeLockContract = await TimeLockFactory.deploy();
    const SelfDestructFactory = await ethers.getContractFactory("MockSelfDestruct",owner);
    this.SelfDestructContract = await SelfDestructFactory.deploy();
    this.owner = owner
  });

  // it("Deposit Function", async function() {
  //   const TokenId = await this.TimeLockContract.Id();
  //   this.TimeLockContract.deposit(10,{value: ethers.utils.parseEther("1.0")});
  //   expect(await this.TimeLockContract.CheckDeposit(TokenId.toNumber())).to.be.eq(this.owner.address);
  //   expect(await this.TimeLockContract.CheckAmountDeposited(TokenId.toNumber())).to.be.eq(ethers.utils.parseEther("1.0"))

  // });


  it("DepositFunctionSelfDestruct",async function() {
    const TokenId = await this.TimeLockContract.Id();
    await this.SelfDestructContract.deposit({value :ethers.utils.parseEther("1.0")});
    await this.SelfDestructContract.selfdestructs(this.TimeLockContract.address);
    console.log(TokenId);  
    //expect(await this.TimeLockContract.CheckDeposit(TokenId.toNumber())).to.be.eq(this.SelfDestructContract.address);
    expect(await this.TimeLockContract.CheckAmountDeposited(TokenId.toNumber())).to.be.eq(ethers.utils.parseEther("1.0"))
  })
});
