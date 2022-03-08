// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "hardhat/console.sol";

contract TokenERC1155 is Initializable, ERC1155Upgradeable, OwnableUpgradeable {

    string public baseURI;
    mapping(uint256 => string) private _hashIPFS;


    function initialize(string[] memory _hashes) public initializer {

        baseURI = "https://ipfs.io/ipfs/";
        
        for(uint256 i; i < _hashes.length; i++)
        {
            _mint(_msgSender(),i , 10, "");
            _hashIPFS[i] = _hashes[i];
            
        }
        
    } 


}