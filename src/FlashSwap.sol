// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IUniswapV2Call.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";

contract FlashSwap is IUniswapV2Callee {
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event Log(string message, uint256 amount);

    function flashLoanSwap(address _tokenBorrow, uint256 _amount) public {
        address pair = IUniswapV2Factory(FACTORY).getPair(WETH, _tokenBorrow);
        require(pair != address(0), "!pair");
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(_tokenBorrow, _amount);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
        require(pair == msg.sender, "Pair is not sender");
        require(sender == address(this), "address this is not who initiate the request of flash loan");
        (address tokenBorrow, uint256 amount) = abi.decode(data, (address, uint256));
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;
        emit Log("amount", amount);
        emit Log("amount0", amount0);
        emit Log("amount1", amount1);
        emit Log("fee", fee);
        emit Log("amount to repay", amountToRepay);
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }
}
