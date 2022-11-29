//contract to test

const { ethers } = require("hardhat")


describe("TokenDeployment",function(){

    let owner,addr1,addr2,addr3

    before(async function(){
        [deployer,addr1,addr2,addr3] = await ethers.getSigners();
        
        const TimeLockFactory = await ethers.getContractFactory('TimeLock',deployer);

        const TimeLock = await  TimeLockFactory.deploy();
    })
})