//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "hardhat/console.sol";

contract NFTMarket is Initializable, ReentrancyGuardUpgradeable, ERC1155Upgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _itemIds; 
    uint256 public commission;
    address public target_account; 

    struct MarketItem {
        uint  itemId;
        address nftContract;
        uint tokenId;
        address payable seller;
        address payable owner;
        uint price;
        uint256 tokenAmount;
        uint256 daysOnSale;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idMarketItem;

    function initialize() public initializer {}


    /// @notice function to create market item
    function createMarketItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint256 _tokenAmount,
        uint256 _daysOnSale) public payable nonReentrant{
         

        _itemIds.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _itemIds.current();

         idMarketItem[itemId] = MarketItem(
            itemId,
            _nftContract,
            _tokenId,
            payable(msg.sender), //address of the seller putting the nft up for sale
            payable(address(0)), //no owner yet (set owner to empty address)
            _price,
            _tokenAmount,
            _daysOnSale,
            false
         );

            //transfer ownership of the nft to the contract itself
            ERC1155Upgradeable(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId, _tokenAmount, "");
        
        }




}