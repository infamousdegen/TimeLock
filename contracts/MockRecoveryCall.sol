// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MockRecoveryCall{
    using ECDSA for bytes32;
    uint id = 1;

    function MessageToSign() public view returns(bytes32){
        bytes32 MessagesToSign = keccak256(abi.encodePacked(id));
        return MessagesToSign;
    }

    function Verify(bytes memory _signature) public view returns(address){
        bytes32 Messages = MessageToSign();
        bytes32 FinalMessage = Messages.toEthSignedMessageHash();
        address _addy = FinalMessage.recover(_signature);
        return _addy;
    }
}