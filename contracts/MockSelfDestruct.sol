// SPDX-License-Identifier: MIT
import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract MockSelfDestruct{
    function deposit() payable public{}

    function selfdestructs(address payable _to) payable public{
        console.log("Inside Selfdestruct");
        selfdestruct(_to);
    }
}