// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//importing Reentrancy modifier


/*things to do 
1) Add events 
2) Add option to add signatures
3) Add an option to remove signatures
4) Role and isVerified both are duplicates fix  it 
5) Add function to view minimum signature
6) Add a functon to check  if an address is a verified party
*/


/*

Design thought: should I use HasRole(Openzeppelin) or internal mapping to check if an address is  allowed to call/ 
The HasRole also has default admin role so that could  be updated to query the original msg.sender?  or maybe not?
Can't figure out the vulnerabilities

*/
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TimeLock is ReentrancyGuard,AccessControl{
    using Address for address payable;
    using ECDSA for bytes32;

    
    struct TimeCheck{
        address DepositAddress;
        uint256 LockedUntil;
        uint256 Value;
        uint256 MinimumSignatures;
        uint256 Nonce;
        mapping(address => bool) isVerified;

    }
    mapping(uint256 => TimeCheck) private DepositForEachId;
    uint256 Id = 1;
    



    function deposit(uint256 _SecondsToDeposit) payable public{
        DepositForEachId[Id].DepositAddress = msg.sender;
        DepositForEachId[Id].LockedUntil = block.timestamp + _SecondsToDeposit;
        DepositForEachId[Id].Value = msg.value;
        Id++;

    }

    function withdraw(uint256 _id) external nonReentrant{
        require(DepositForEachId[_id].DepositAddress == msg.sender,"permission denied");
        _withdraw(_id,payable(msg.sender));
    }

    function SetupRecovery(uint256 _id,address[] calldata _address,uint256 _MinimumSignatures) external {
        require(_address.length != 0,"Address array is 0");
        //Not required to check if the id is valid because DepositAddress of invalid id will be 0 address
        require(DepositForEachId[_id].DepositAddress == msg.sender,"You do not have permission");
        for(uint256 i = 0; i<= _address.length ; i++){
            require(_address[i] != address(0),"0 address detected");
            DepositForEachId[Id].isVerified[_address[i]] = true;

        }

        DepositForEachId[_id].MinimumSignatures = _MinimumSignatures;       
    }


    function RecoveryCall(uint256 _id,bytes[] memory signatures,address payable _ToAddress) external{
        require(DepositForEachId[_id].DepositAddress != address(0) ,"Invalid id being called");
        require(DepositForEachId[_id].isVerified[msg.sender],"You do not have permission for this id");

        //what if the same signature is passed twice then MinimumSignatures require will pass update it

        require(_ToAddress != address(0) && signatures.length >= DepositForEachId[_id].MinimumSignatures,"Sending to wrong address");  

        for(uint256 i = 0; i<=signatures.length ; i++){
            address ReceivedAddress = VerifySignature(_id, DepositForEachId[_id].Nonce,_ToAddress,signatures[i]);
            require(DepositForEachId[_id].isVerified[ReceivedAddress] && ReceivedAddress != address(0),"Invalid address in signature");
        }

        _withdraw(_id, _ToAddress);
        DepositForEachId[_id].Nonce++;




    }


    function _withdraw(uint256 _id,address payable _AddressToSend) private {
        require(DepositForEachId[_id].LockedUntil <= block.timestamp,"Enough time has not passed");
        DepositForEachId[_id].Value = 0;
        _AddressToSend.sendValue(DepositForEachId[_id].Value);

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


}