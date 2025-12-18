// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {cSavings} from "../src/cSavings.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Custom errors
error cSavings__ZeroAmount();
error cSavings__InsufficientBalance();
error cSavings__TransferFailed();
error cSavings__NotOwner();

// Mock ERC20 for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock cUSD", "cUSD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract cSavingsTest is Test {
    cSavings savings;
    MockERC20 cusd;
    address owner;
    address user1;
    address user2;

    uint256 initialRewardRate = 1e15; // 0.001 per second

    function setUp() public {
        cusd = new MockERC20();
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        savings = new cSavings(address(cusd), initialRewardRate);

        // Mint cUSD to users
        cusd.mint(user1, 1000e18);
        cusd.mint(user2, 1000e18);
        cusd.mint(owner, 1000e18);

        // Approve savings contract
        vm.prank(user1);
        cusd.approve(address(savings), type(uint256).max);
        vm.prank(user2);
        cusd.approve(address(savings), type(uint256).max);
        vm.prank(owner);
        cusd.approve(address(savings), type(uint256).max);
    }

    function testDeposit() public {
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit cSavings.Deposited(user1, 100e18);
        savings.deposit(100e18);

        assertEq(savings.balanceOf(user1), 100e18);
        assertEq(savings.totalDeposits(), 100e18);
        assertEq(cusd.balanceOf(address(savings)), 100e18);
    }

    function testDepositZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(cSavings__ZeroAmount.selector);
        savings.deposit(0);
    }

    function testWithdraw() public {
        vm.prank(user1);
        savings.deposit(100e18);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit cSavings.Withdrawn(user1, 50e18);
        savings.withdraw(50e18);

        assertEq(savings.balanceOf(user1), 50e18);
        assertEq(savings.totalDeposits(), 50e18);
        assertEq(cusd.balanceOf(user1), 950e18); // 1000 - 100 + 50
    }

    function testWithdrawInsufficientBalance() public {
        vm.prank(user1);
        savings.deposit(100e18);

        vm.prank(user1);
        vm.expectRevert(cSavings__InsufficientBalance.selector);
        savings.withdraw(200e18);
    }

    function testWithdrawZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(cSavings__ZeroAmount.selector);
        savings.withdraw(0);
    }

    function testRewards() public {
        vm.prank(user1);
        savings.deposit(100e18);

        // Advance time by 10 seconds
        vm.warp(block.timestamp + 10);

        uint256 earned = savings.earned(user1);
        assertEq(earned, 10 * initialRewardRate); // 10 * 1e15 = 1e16

        // Fund rewards
        savings.fundRewards(1e18);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit cSavings.RewardPaid(user1, earned);
        savings.claimRewards();

        assertEq(savings.rewards(user1), 0);
        assertEq(cusd.balanceOf(user1), 1000e18 - 100e18 + earned);
    }

    function testMultipleUsers() public {
        vm.prank(user1);
        savings.deposit(100e18);
        vm.prank(user2);
        savings.deposit(100e18);

        vm.warp(block.timestamp + 10);

        uint256 earned1 = savings.earned(user1);
        uint256 earned2 = savings.earned(user2);
        assertEq(earned1, earned2); // Equal shares

        // Fund
        savings.fundRewards(2e18);

        vm.prank(user1);
        savings.claimRewards();
        vm.prank(user2);
        savings.claimRewards();

        assertEq(savings.rewards(user1), 0);
        assertEq(savings.rewards(user2), 0);
    }

    function testSetRewardRate() public {
        uint256 newRate = 2e15;
        vm.expectEmit(false, false, false, true);
        emit cSavings.RewardRateUpdated(initialRewardRate, newRate);
        savings.setRewardRate(newRate);
        assertEq(savings.rewardRate(), newRate);
    }

    function testSetRewardRateNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(cSavings__NotOwner.selector);
        savings.setRewardRate(2e15);
    }

    function testFundRewards() public {
        vm.expectEmit(false, false, false, true);
        emit cSavings.RewardsFunded(100e18);
        savings.fundRewards(100e18);
        assertEq(cusd.balanceOf(address(savings)), 100e18);
    }

    function testFundRewardsNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(cSavings__NotOwner.selector);
        savings.fundRewards(100e18);
    }

    function testExit() public {
        vm.prank(user1);
        savings.deposit(100e18);
        vm.warp(block.timestamp + 10);
        savings.fundRewards(1e18);

        vm.prank(user1);
        savings.exit();

        assertEq(savings.balanceOf(user1), 0);
        assertEq(savings.rewards(user1), 0);
    }
}