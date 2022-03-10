//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LINK is ERC20{
    constructor() ERC20("ChainLink Token", "LINK"){}

    function faucet(address recipient, uint amount) external{
    _mint(recipient, amount);
}


}



