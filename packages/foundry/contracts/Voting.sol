// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { console2 } from "../lib/forge-std/src/console2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract votekh{
    IERC20 public drToken;          //decentralized resistance token
    uint256 public voteOpenPeriod;  //time period vote is open

    constructor(IERC20 _drTokenAddress, uint256 _voteOpenPeriod){
        drToken = IERC20(_drTokenAddress);
        voteOpenPeriod = _voteOpenPeriod;
    }


}
// Good luck!
