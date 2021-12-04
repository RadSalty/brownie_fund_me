// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol"; // uses the brownie-config file to define where @chainlink is
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol"; // uses the brownie-config file to define where @chainlink is

contract FundMe {
    using SafeMathChainlink for uint256; //inherits safemath for uint256 so functions do not have to be uses explicitly

    mapping(address => uint256) public addressToAmountFunded; // creates an object which stores the address and the amount funded to the contract
    address[] public funders; // list of funding addresses
    address public owner; // address of the owner
    AggregatorV3Interface public priceFeed; // sets the chainlink interface to pricefeed

    // constructor initialises as soon as the contract is deployed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed); // sets the priceFeed to the address set in the deploy.py, defined in the brownie-config file
        owner = msg.sender; // sets the deploying wallet as the owner
    }

    // defines function, name, public access and that the function involves payment
    function fund() public payable {
        uint256 mimimumUSD = 50 * 10**18; // sets minimum amount to $50
        require(
            getConversionRate(msg.value) >= mimimumUSD,
            "You need to spend more ETH!"
        ); // require ensures that it is met or the transaction fails, first arguement is the requirement, second is the error message
        addressToAmountFunded[msg.sender] += msg.value; // updates the object for each address to new funding amount
        funders.push(msg.sender); // adds address to list of funders
    }

    // public view function which shows the version of the pricefeed from the chainlink node
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    //
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // calls the AggregatorV3Interface latestRoundData function, which returns 5 variablesm only need the second variable
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance); // withdraws balance to owner

        // creates a for loop, iterates through the list and resets all accounts to 0 funding
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; //
        }
        funders = new address[](0); // resets the funders list once a withdraw event has occured
    }
}
