// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FlashSwap} from "../src/FlashSwap.sol";
import {IERC20} from "../src/IERC20.sol";

contract FlashSwapTest is Test {
    // Define constants for the test
    address private constant UNI_WHALE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant TOKEN_TO_BORROW = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI token address
    uint256 private constant AMOUNT_TO_BORROW = 1000 * 10 ** 18; // 1000 UNI tokens

    FlashSwap private flashSwap;
    IERC20 private uniToken;

    function setUp() public {
        flashSwap = new FlashSwap();
        uniToken = IERC20(TOKEN_TO_BORROW);

        // Deal ETH to the whale address for covering gas fees
        vm.deal(UNI_WHALE, 1 ether);

        // Impersonate the whale address to simulate transactions
        vm.startPrank(UNI_WHALE);

        // Ensure the whale has enough UNI tokens for the setup
        uint256 whaleBalance = uniToken.balanceOf(UNI_WHALE);
        require(whaleBalance > 10 * 10 ** 18, "Whale does not have enough UNI balance");

        // Transfer UNI tokens to the flash swap contract to cover the flash loan fee
        uniToken.transfer(address(flashSwap), 10 * 10 ** 18);

        vm.stopPrank();
    }

    function testFlashLoanSwap() public {
        // Impersonate the whale to execute the flash loan swap
        vm.startPrank(UNI_WHALE);

        // Capture the balance before the flash loan swap
        uint256 balanceBefore = uniToken.balanceOf(address(flashSwap));

        // Perform the flash loan swap
        flashSwap.flashLoanSwap(address(uniToken), AMOUNT_TO_BORROW);

        // Capture the balance after the flash loan swap
        uint256 balanceAfter = uniToken.balanceOf(address(flashSwap));

        // Validate that the flash loan was executed correctly
        assertGt(balanceBefore, 0, "Contract balance before swap should be greater than 0");
        // The balance after the swap should account for the repayment fee deducted from the balance before
        assertTrue(balanceAfter <= balanceBefore, "Contract balance after swap should not exceed initial balance");

        // Stop impersonating the whale
        vm.stopPrank();
    }
}
