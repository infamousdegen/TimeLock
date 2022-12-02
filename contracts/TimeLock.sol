// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* TimeLock Contract which doest the following things
 
       1) Allows users to deposit and specify a time to lock their "ETHER"
       2) Only allow users to withdraw after a specified withdrawal time period has finished
       3) Provides a "recovery mechanism" to allow users to withdraw if they loose access to their wallet 
              (will check whether the specified time period has passed)



*/


/*things to do 
1) Add events 
2) Add option to add signatures :- Done
3) Add an option to remove signatures :- Done
4) Role and isVerified both are duplicates fix  it :- Fixed
5) Add function to view minimum signatures : Done
6) Add a functon to check  if an address is a verified party :Done
7) Add fallback() function :- Done but check for vulnerabilities
8) What if a token was accidently transferred to this address?
9) Add a function to call arbitrary internal function for the deployer of te contract? :pending
10) Provide an option for users to deposit their funds in a yield earning farms

*/


/*
Design thoughts:

1: should I use HasRole(Openzeppelin) or internal mapping to check if an address is  allowed to call/ 
The HasRole also has default admin role so that could  be updated to query the original msg.sender?  or maybe not?
Can't figure out the vulnerabilities

2: SHould i uses mapping to combine DepositAddress and Value

*/
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract TimeLock is ReentrancyGuard,AccessControl{
    using Address for address payable;
    using ECDSA for bytes32;


    modifier CheckIsOwner(uint256 _id) {
        require(DepositForEachId[_id].DepositAddress == msg.sender,"Permission Denied");
        _;
        
    }

    
    struct TimeCheck{
        //default value of address = addres(0)
        address DepositAddress;
        //default value of Uint256 = 0
        uint256 LockedUntil;
        uint256 Value;
        uint256 MinimumSignatures;
        uint256 Nonce;  
        //default value of this mapping is address(0) and bool is 0
        mapping(address => bool) isVerified;

    }
    //changed deposit for eachId into public
    mapping(uint256 => TimeCheck) private DepositForEachId;
    uint256 public Id = 1;

    
    



    function deposit(uint256 _SecondsToDeposit) payable public{
        DepositForEachId[Id].DepositAddress = msg.sender;
        DepositForEachId[Id].LockedUntil = block.timestamp + _SecondsToDeposit;
        DepositForEachId[Id].Value = msg.value;
        Id++;

    }

    //The main withdrawal function which is supposed to workonly if the owner of Id is called

    function withdraw(uint256 _id) external CheckIsOwner(_id) nonReentrant{
        _withdraw(_id,payable(msg.sender));
    }

    //This functions allows the owner of the id to setup address which can later be used to recover the minimum if the original owner looses his address

    function AddSigners(uint256 _id,address[] calldata _address,uint256 _MinimumSignatures) external CheckIsOwner(_id){
        require(_address.length != 0,"Address array is 0");
        //Not required to check if the id is valid because DepositAddress of invalid id will be 0 address
        for(uint256 i = 0; i<= _address.length ; i++){
            require(_address[i] != address(0),"0 address detected");
            DepositForEachId[Id].isVerified[_address[i]] = true;

        }

        DepositForEachId[_id].MinimumSignatures = _MinimumSignatures;       
    }


    function RemoveSigners(uint256 _id,address[] calldata _address,uint256 _MinimumSignatures) public CheckIsOwner(_id){
        for(uint256 i = 0; i<= _address.length ; i++){
            DepositForEachId[Id].isVerified[_address[i]] = false;

        }
        DepositForEachId[_id].MinimumSignatures = _MinimumSignatures;

        
    }

    //This is the withdrawal call which "I believe" checks if the signers are valid address for that id , 
    //makng sure it doesnt work if we copy paste previous calldata


    function RecoveryCall(uint256 _id,bytes[] memory signatures,address payable _ToAddress) external{
        require(DepositForEachId[_id].DepositAddress != address(0) ,"Invalid id being called");
        require(DepositForEachId[_id].isVerified[msg.sender],"You do not have permission for this id");



        require(_ToAddress != address(0) && signatures.length >= DepositForEachId[_id].MinimumSignatures,"Sending to wrong address");  

        for(uint256 i = 0; i<=signatures.length ; i++){
            address ReceivedAddress = VerifySignature(_id, DepositForEachId[_id].Nonce,_ToAddress,signatures[i]);
            //Not required to check if the ReceivedAddress is 0 because .isVerified[0] = false?
            require(DepositForEachId[_id].isVerified[ReceivedAddress] ,"Invalid address in signature");
        }
        DepositForEachId[_id].Nonce++;
        _withdraw(_id, _ToAddress);




    }


    //this is the main _withdraw function should be only be accessed with eitheir 
    // 1) Withdraw() or RecoveryCall()
    function _withdraw(uint256 _id,address payable _AddressToSend) private {
        require(DepositForEachId[_id].LockedUntil <= block.timestamp,"Enough time has not passed");
        DepositForEachId[_id].Value = 0;
        _AddressToSend.sendValue(DepositForEachId[_id].Value);

    }


    //function to UpdateSignature 
    //should be called by the owner of that particular id
    function UpdateSignatures(uint256 _id,uint256 _MinimumSignatures) external CheckIsOwner(_id){
        require(_MinimumSignatures >=1,"Minimum 1 signatures should  be mentioned");
        DepositForEachId[_id].MinimumSignatures = _MinimumSignatures;
    }

    function VerifySignature(uint256 _id,uint256 _Nonce,address _to,bytes memory _Signatures) view internal returns(address){
        bytes32 ethSignedMessage = CreateMessageToSign(_id,_Nonce,_to);
        address _Received = ethSignedMessage.recover(_Signatures);
        return(_Received);
    }

    function TimeLeft(uint256 _id) public view returns(uint256){
        return(DepositForEachId[_id].LockedUntil - block.timestamp);
    }

    function CheckAmountDeposited(uint256 _id) public view returns(uint256){
        return(DepositForEachId[_id].Value);
    }

    function CreateMessageToSign(uint256 _id,uint256 _Nonce,address _to) public view returns(bytes32){
        require(DepositForEachId[_id].DepositAddress != address(0),"Invalid Id called");
        bytes32 Hash = keccak256(abi.encodePacked(_id,_Nonce,_to));
        return Hash.toEthSignedMessageHash();
    }

    function ViewMinimumSignatures(uint256 _id) public view returns(uint256){
        return(DepositForEachId[_id].MinimumSignatures);
    }


    function CheckIsVerified(uint256 _id,address _address) public view returns(bool){
        return(DepositForEachId[_id].isVerified[_address]);
    }

    function CheckDeposit(uint256 _id) external view returns(address){
        return(DepositForEachId[_id].DepositAddress);
    }


    //Any vulnerabilities possible here? maybe by sending  not enough gas?
    //These fallback wont be called  if eth is sent using selfdestruct
    fallback() external payable{
        console.log("here");
        //msg.sender will be address(this)?
        //deposit(10);
    }

    //Any vulnerabilities possible here? maybe by sending  not enough gas?
    receive() external payable{
        console.log("Here");
        //deposit(10);
    }
}