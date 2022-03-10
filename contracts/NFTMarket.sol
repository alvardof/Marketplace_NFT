//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";

contract NFTMarket is Initializable, AccessControlUpgradeable, UUPSUpgradeable ,  ReentrancyGuardUpgradeable {

    /// @notice declaration of variables

    using Counters for Counters.Counter;
    uint256 public commission;
    IERC20 private dai;
    IERC20 private link;
    AggregatorV3Interface internal priceFeedEther;
    AggregatorV3Interface internal priceFeedDai;
    AggregatorV3Interface internal priceFeedLink;
    Counters.Counter private _itemIds; 
    address public target_account;
    address public _owner;


    struct MarketItem {
        uint  itemId;
        address nftContract;
        uint tokenId;
        address payable seller;
        uint price;
        uint256 tokenAmount;
        uint256 daysOnSale;
        bool sold;
        bool cancel;
    }

    mapping(uint256 => MarketItem) public idMarketItem;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");



    /// @notice events

    event sell(
        string,
        uint idSell
    );

    event buy(
        string,
        uint idBuy
    );

    event cancel(
        string,
        uint idCancel
    );


    /// @notice contract initialization

    function initialize(address _daiAddess , address _linkAddess) public initializer {

        dai = IERC20(_daiAddess);
        link = IERC20(_linkAddess);
        commission = 1;
        priceFeedEther = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        priceFeedDai = AggregatorV3Interface(0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF);
        priceFeedLink = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);

        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        
        
    }

    function _authorizeUpgrade(address newAuthorize) internal onlyRole(UPGRADER_ROLE) override{}


    /// @notice function to create market item

    function createMarketItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint256 _tokenAmount,
        uint256 _daysOnSale) public payable nonReentrant{
         
            _itemIds.increment(); 
            uint256 itemId = _itemIds.current();

            require(ERC1155Upgradeable(_nftContract).isApprovedForAll(msg.sender, address(this)), "no permission to sell token");

            idMarketItem[itemId] = MarketItem(
                itemId,
                _nftContract,
                _tokenId,
                payable(_msgSender()),
                _price,
                _tokenAmount,
                _daysOnSale,
                false,
                false
            );

            emit sell("new tokens for sale",itemId);
        }


        /// @notice function to buy by paying with ETHER

        function buyETH(uint256 offerId) external payable nonReentrant{

            require(idMarketItem[offerId].sold == false, "tokens already sold");
            require(idMarketItem[offerId].cancel == false,"sale cancelled");

            uint256 priceETH = getLatestPriceEth();

            uint ETH = msg.value / 1e10;

            uint priceToken = idMarketItem[offerId].price;

            require((ETH * priceETH) / 1e18 >= priceToken,"sale cancelled");

            idMarketItem[offerId].sold = true;

            uint256 tokenId = idMarketItem[offerId].tokenId;

            uint256 amountToken = idMarketItem[offerId].tokenAmount;

            address payable seller = idMarketItem[offerId].seller;

            uint256 comissionPay = ((priceToken / priceETH) / 100 * commission) * 1e10;

            uint256 sellerPay = (priceToken  / priceETH) * 1e10 - comissionPay;

            (bool sent,) = seller.call{value: sellerPay}("");

            require(sent,"payment not made ");

            ERC1155Upgradeable(idMarketItem[offerId].nftContract).safeTransferFrom(seller, msg.sender,tokenId , amountToken, "");

            if(msg.value > sellerPay + comissionPay){
                (bool sended,) = msg.sender.call{value: msg.value - (sellerPay + comissionPay)}("");
                
                require(sended, "funds not returned");
            }

                emit sell("buy token paying with ETHER",offerId);

        }

         /// @notice function to buy by paying with DAI

        function buyDai(uint256 offerId) external payable nonReentrant{

            require(idMarketItem[offerId].sold == false, "tokens already sold");

            require(idMarketItem[offerId].cancel == false, "sale cancelled");

            uint256 priceDAI = getLatestPriceDai();

            uint amountDAI = (idMarketItem[offerId].price / priceDAI) * 1e18;

            dai.approve(address(this), amountDAI);

            dai.transferFrom(msg.sender, address(this), (amountDAI / 100 * commission));

            dai.transferFrom(msg.sender, idMarketItem[offerId].seller, amountDAI - (amountDAI / 100 * commission));

            uint256 tokenId = idMarketItem[offerId].tokenId;

            uint256 amountToken = idMarketItem[offerId].tokenAmount;

            address payable seller = idMarketItem[offerId].seller;

            ERC1155Upgradeable(idMarketItem[offerId].nftContract).safeTransferFrom(seller, msg.sender,tokenId , amountToken, "");

            emit sell("buy token paying with DAI",offerId);
        }

         /// @notice function to buy by paying with LINK

        function buyLink(uint256 offerId) external payable nonReentrant{

            require(idMarketItem[offerId].sold == false, "tokens already sold");
            
            require(idMarketItem[offerId].cancel == false, "sale cancelled");

            uint256 priceLINK = getLatestPriceLink();

            uint amountLINK = (idMarketItem[offerId].price / priceLINK) * 1e18;

            link.approve(address(this), amountLINK);

            link.transferFrom(msg.sender, address(this), (amountLINK / 100 * commission));

            link.transferFrom(msg.sender, idMarketItem[offerId].seller, amountLINK - (amountLINK / 100 * commission));

            uint256 tokenId = idMarketItem[offerId].tokenId;

            uint256 amountToken = idMarketItem[offerId].tokenAmount;

            address payable seller = idMarketItem[offerId].seller;

            ERC1155Upgradeable(idMarketItem[offerId].nftContract).safeTransferFrom(seller, msg.sender,tokenId , amountToken, "");

            emit sell("buy token paying with LINK",offerId);
        }

         /// @notice function to get ETHER price

        function getLatestPriceEth() internal view returns(uint){
            (,int256 price,,,) = priceFeedEther.latestRoundData();
            return uint(price);  
        }

         /// @notice function to get DAI price

        function getLatestPriceDai() internal view returns(uint){
            (,int256 price,,,) = priceFeedDai.latestRoundData();
            return uint(price);  
        }

         /// @notice function to get LINK price

        function getLatestPriceLink() internal view returns(uint){
            (,int256 price,,,) = priceFeedLink.latestRoundData();
            return uint(price);  
        }

         /// @notice function to cancel sale

        function CancelSale(uint offerId) public{
        
            require(idMarketItem[offerId].sold == false,"tokens already sold");
            require(idMarketItem[offerId].seller == msg.sender,"incorrect owner");
            require(idMarketItem[offerId].cancel == false,"sale cancelled");
            ERC1155Upgradeable(idMarketItem[offerId].nftContract).setApprovalForAll(address(this), false);
            idMarketItem[offerId].cancel == true;

                emit sell("cancellation of sale",offerId);
        }




}

