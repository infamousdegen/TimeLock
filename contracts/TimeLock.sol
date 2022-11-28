// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//importing Reentrancy modifier

//dont forget to add reentrancy modifier to withdraw

contract TimeLock{

    
    struct TimeCheck{
        address DepositAddress;
        uint256 LockedUntil;
        uint256 Value;
    }
    mapping(uint256 => TimeCheck) private DepositForEachId;
    mapping(address => uint256[]) public AddressIds;
    uint256 Id = 1;



    function deposit(uint256 _SecondsToDeposit) payable public{
        DepositForEachId[Id].DepositAddress = msg.sender;
        DepositForEachId[Id].LockedUntil = block.timestamp + _SecondsToDeposit;
        DepositForEachId[Id].Value = msg.value;
        AddressIds[msg.sender].push(Id);
        Id++;

    }

    function withdraw(uint256 _id) public {
        require(DepositForEachId[_id].DepositAddress == msg.sender,"permission denied");
        require(DepositForEachId[_id].LockedUntil <= block.timestamp,"Enough time has not passed");
        DepositForEachId[_id].Value = 0;
        (bool sent,) = payable(msg.sender).call{value: DepositForEachId[_id].Value}("");
        require(sent , "Transfer Failed");

    }

    function SetupRecover(uint256 _id,address[] calldata _address) public{
        require(DepositForEachId[_id].DepositAddress == msg.sender);
    }

    function CheckId(address _address) public view returns(uint256[] memory ){
        return(AddressIds[_address]);
    }

    function TimeLeft(uint256 _id) public view returns(uint256){
        return(DepositForEachId[_id].LockedUntil - block.timestamp);
    }

    function CheckAmountDeposited(uint256 _id) public view returns(uint256){
        return(DepositForEachId[_id].Value);
    }


}