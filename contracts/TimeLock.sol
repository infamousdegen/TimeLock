// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//importing Reentrancy modifier

//dont forget to add reentrancy modifier to withdraw
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
        bytes32 Role;
        mapping(address => bool) isVerified;

    }
    mapping(uint256 => TimeCheck) private DepositForEachId;
    mapping(address => uint256[]) public AddressIds;
    bytes32 constant public TrustedCaller = keccak256("TrustedCaller");
    uint256 Id = 1;
    



    function deposit(uint256 _SecondsToDeposit) payable public{
        DepositForEachId[Id].DepositAddress = msg.sender;
        DepositForEachId[Id].LockedUntil = block.timestamp + _SecondsToDeposit;
        DepositForEachId[Id].Value = msg.value;
        AddressIds[msg.sender].push(Id);
        DepositForEachId[Id].Role = keccak256(abi.encodePacked(Id));
        
        Id++;

    }

    function withdraw(uint256 _id) public nonReentrant{
        require(DepositForEachId[_id].DepositAddress == msg.sender,"permission denied");
        _withdraw(_id,payable(msg.sender));
    }

    function SetupRecovery(uint256 _id,address[] calldata _address,uint256 _MinimumSignatures) public{
        require(_address.length != 0,"Address array is 0");
        //Not required to check if the id is valid because DepositAddress of id which is invalid will be 0 address
        require(DepositForEachId[_id].DepositAddress == msg.sender,"Invalid Id called");
        for(uint256 i = 0; i<= _address.length ; i++){
            require(_address[i] != address(0),"0 address detected");
            DepositForEachId[Id].isVerified[_address[i]] = true;
            grantRole(DepositForEachId[_id].Role,_address[i]);

        }

        DepositForEachId[_id].MinimumSignatures = _MinimumSignatures;       
    }

    //prevent copy pasting of signatures by including a uniqure transaction count modifier

    function RecoveryCall(uint256 _id,bytes[] memory signatures,address payable _ToAddress) public{
        require(DepositForEachId[_id].DepositAddress != address(0) && signatures.length >= DepositForEachId[_id].MinimumSignatures,"Invalid id being called");
        require(hasRole(DepositForEachId[_id].Role,msg.sender),"You do not have permission for this id");
        require(_ToAddress != address(0),"Sending to wrong address");  

        for(uint256 i = 0; i<=signatures.length ; i++){
            address ReceivedAddress = VerifySignature(_id, DepositForEachId[_id].Nonce,_ToAddress,signatures[i]);
            require(DepositForEachId[_id].isVerified[ReceivedAddress] && ReceivedAddress != address(0),"Invalid address in signature");
        }

        _withdraw(_id, _ToAddress);
        DepositForEachId[_id].Nonce++;




    }


    function _withdraw(uint256 _id,address payable _AddressToSend) private nonReentrant{
        require(DepositForEachId[_id].LockedUntil <= block.timestamp,"Enough time has not passed");
        DepositForEachId[_id].Value = 0;
        _AddressToSend.sendValue(DepositForEachId[_id].Value);

    }

    function VerifySignature(uint256 _id,uint256 _Nonce,address _to,bytes memory _Signatures) view internal returns(address){
        bytes32 ethSignedMessage = CreateMessageToSign(_id,_Nonce,_to);
        address _Received = ethSignedMessage.recover(_Signatures);
        return(_Received);
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

    function CreateMessageToSign(uint256 _id,uint256 _Nonce,address _to) public view returns(bytes32){
        require(DepositForEachId[_id].DepositAddress != address(0),"Invalid Id called");
        bytes32 Hash = keccak256(abi.encodePacked(_id,_Nonce,_to));
        return Hash.toEthSignedMessageHash();
    }


}