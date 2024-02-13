// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    uint256 number = 1;
    uint256 GAS_Price = 1;
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // us -> FundMeTest -> FundMe
        DeployFundMe deployfundMe = new DeployFundMe();
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        fundMe = deployfundMe.run();
        vm.deal(USER,STARTING_BALANCE);
    }

    function testMinimumdollarisfive() public {

        assertEq(fundMe.MINIMUM_USD(), 5e18);

    }

    function testOwner() public {

        // console.log(fundMe.i_owner());
       // console.log(msg.sender);  // who ever is calling the FundMeTest
        // console.log(address(this)); // Gives me address of FundMeTest 
        assertEq(fundMe.getOwner(), msg.sender);
    }


    function testVersionIsAccurate() public {

        uint256 version =  fundMe.getVersion();
        assertEq(version, 4);

    }

    function testFundFailsWithoutEnoughEth() public returns(uint256) {
        vm.expectRevert();
        fundMe.fund();
        return 0;
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER); // The next TX will be sent by USER.
        fundMe.fund{value: SEND_VALUE }();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArraysOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw () public funded {

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();

    }

    function testWithdrawWithSingleFunder() public funded(){

        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_Price);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft(); 
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);


        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance + startingOwnerBalance,endingOwnerBalance);

    }

    function testWithdrawfromMultipleFunders() public {
        //Arrange

        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i=startingFunderIndex;i<numberOfFunders;i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        assert(address(fundMe).balance == 0 );
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }

    function testWithdrawfromMultipleFundersCheaper() public {
        //Arrange

        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i=startingFunderIndex;i<numberOfFunders;i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        //Assert
        assert(address(fundMe).balance == 0 );
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }


}