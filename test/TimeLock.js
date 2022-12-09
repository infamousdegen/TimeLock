const { ethers } = require("hardhat");
const { expect } = require("chai");
const {time} = require("@nomicfoundation/hardhat-network-helpers");






describe("TokenDeployment", async function () {

  before("SettingUp", async function () {
    //setting up the environment
    let [owner, addr1, signer1, signer2] = await ethers.getSigners();

    const TimeLockFactory = await ethers.getContractFactory("TimeLock", owner);
    this.TimeLockContract = await TimeLockFactory.deploy();
    const SelfDestructFactory = await ethers.getContractFactory("MockSelfDestruct",owner);
    this.SelfDestructContract = await SelfDestructFactory.deploy();
    this.owner = owner
    this.addr1 = addr1
    this.signer1 = signer1;
    this.signer2 = signer2;
    this.AddresssToId = {};
  })



  it("Deposit Function", async function() {
    const TokenId = await this.TimeLockContract.Id();
    this.AddresssToId[this.owner.address] = TokenId;
    await this.TimeLockContract.deposit(10,{value: ethers.utils.parseEther("1.0")});
    expect(await this.TimeLockContract.CheckDeposit(TokenId.toNumber())).to.be.eq(this.owner.address);
    expect(await this.TimeLockContract.CheckAmountDeposited(TokenId.toNumber())).to.be.eq(ethers.utils.parseEther("1.0"))

  });


  it("Checking Invalid Address Calling",async function(){
    //Checking if an invalid id is able to call
    try{
      await network.provider.send("hardhat_setBalance", [
        this.addr1.address,
        "0x0",
      ]);
      this.TimeLockContract.connect(this.addr1).withdraw(1)
      expect(await ethers.provider.getBalance(this.addr1.address)).to.be.eq(ethers.utils.parseEther("1.0"));
    }
    catch(err){
      console.log("Iinvalid address Calling");
    }

  })

  it("Valid caller but enogh time has not passed",async function(){

    try{    
      let InTokenId = this.AddresssToId[this.owner.address];;
      await network.provider.send("hardhat_setBalance", [
        this.owner.address,
        "0x1BC16D674EC80000",//setting balance 
      ]);
  
      await this.TimeLockContract.withdraw(InTokenId);
      expect(await ethers.provider.getBalance(this.owner.adddress)).to.be.eq(ethers.utils.parseEther("2.0"));}

    catch(err){
      console.log("Enough time has not passed");
    }
  })

  // it("Legit Withdrawl",async function(){
  //   let InTokenId = this.AddresssToId[this.owner.address];
  //   await time.increase(3600);
  //   await network.provider.send("hardhat_setBalance", [
  //     this.owner.address,
  //     "0x1BC16D674EC80000",//setting balance 
  //   ]);
  //   await this.TimeLockContract.withdraw(InTokenId);
  // })


  it("AddSigners",async function() {

    let InTokenId = this.AddresssToId[this.owner.address];
    let address = [this.signer1.address,this.signer2.address,this.owner.address]
    await this.TimeLockContract.AddSigners(InTokenId,address,3);
    for(let i =0; i<3 ; i++){
      expect(await this.TimeLockContract.CheckIsVerified(InTokenId,address[i])).to.be.true
    }

  })

  //malicious signer

  it("MaliciousSigners",async function(){
    try{
    let InTokenId = this.AddresssToId[this.owner.address];
    let address = [this.signer1.address,this.signer2.address,this.owner.address]
    await this.TimeLockContract.connect(this.signer1.address).AddSigners(InTokenId,address,3);
    for(let i =0; i<3 ; i++){
      expect(await this.TimeLockContract.CheckIsVerified(InTokenId,address[i])).to.be.true
    }}
    catch{
      console.log("Malicious Address calling AddSigners")
    }

  })

  it("RemoveSigners",async function(){
    let InTokenId = this.AddresssToId[this.owner.address];
    let address = [this.signer1.address,this.signer2.address,this.owner.address]
    await this.TimeLockContract.RemoveSigners(InTokenId,address,0);

    for(let i =0; i<3 ; i++){
      expect(await this.TimeLockContract.CheckIsVerified(InTokenId,address[i])).to.be.false
    }

  })

  it("MaliciousRemoveSigner",async function(){
    try{
      let InTokenId = this.AddresssToId[this.owner.address];
      let address = [this.signer1.address,this.signer2.address,this.owner.address]
      await this.TimeLockContract.connect(this.signer1.address).RemoveSigners(InTokenId,address,0);

      for(let i =0; i<3 ; i++){
        expect(await this.TimeLockContract.CheckIsVerified(InTokenId,address[i])).to.be.false
      }
    }
    catch{
      console.log("Malicious address Calling Remove Signer")
    }

  })


  it("AddSignersForRecoveryCall",async function() {

    let InTokenId = this.AddresssToId[this.owner.address];
    let address = [this.signer1.address,this.signer2.address,this.owner.address]
    await this.TimeLockContract.AddSigners(InTokenId,address,3);
    for(let i =0; i<3 ; i++){
      expect(await this.TimeLockContract.CheckIsVerified(InTokenId,address[i])).to.be.true
    }

  })

  it("RecoverCall",async function(){
    await time.increase(3600);
    let InTokenId = this.AddresssToId[this.owner.address];
    let  Address = [this.signer1,this.signer2,this.owner]
    let SignedDatatypeArray = [];
    let Nonce = ((await this.TimeLockContract.DepositForEachId(InTokenId))["Nonce"]).toNumber()
    let MessageToSign =  ethers.utils.arrayify(await this.TimeLockContract.CreateMessageToSign(InTokenId,Nonce,this.addr1.address));

    for(let i=0 ; i<3 ; i++){
      signer = Address[i]
      let SignedMessage = await signer.signMessage(MessageToSign);
      SignedDatatypeArray.push(SignedMessage)

    }
    console.log(await this.TimeLockContract.CheckAmountDeposited(InTokenId))
    await this.TimeLockContract.connect(this.signer1).RecoveryCall(InTokenId,SignedDatatypeArray,this.addr1.address);
    console.log(await this.addr1.getBalance())


  })



})