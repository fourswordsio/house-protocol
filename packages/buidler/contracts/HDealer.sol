pragma solidity >=0.6.0 <0.7.0;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "./base/HConst.sol";
import {IHPoolFactory} from "./base/IHPoolFactory.sol";
import {IHPool} from "./base/IHPool.sol";
import {IERC20} from "./base/IERC20.sol";
//add gulp: https://ethereum.stackexchange.com/questions/84851/how-to-withdraw-other-erc20-tokens-besides-ethereum-from-my-contract

contract HDealer is VRFConsumerBase, HConst{
    bytes32  internal keyHash;
    uint256 internal fee;
    address private _dealerOwner;

    IHPoolFactory public IPoolF;
    IHPool public IPool;
    IERC20 public I20;
        
    struct game {
            uint b;
            address pool;
    }

    mapping(bytes32 => game) public games;
            /**
            *Constructor inherits VRFConsumerBase
            * 
            * Network: Kovan
            * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
            * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
            * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
            */
            constructor(address poolFactory, address dealerOwner) 
            VRFConsumerBase(VRF_Coordinator, LINK_Token) public {
            keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
            fee = 0.1 * 10 ** 18; // 0.1 LINK
            _dealerOwner = dealerOwner;
            IPoolF = IHPoolFactory(poolFactory);
            }

            /** 
            * Requests randomness from a user-provided seed paid from contract balance
            */
            function roll(uint bet, uint edge, uint b, address token, uint256 userProvidedSeed) public {
                     require((b >= BONE.div(100)) && (b <= BONE.mul(100)));
                     require(bet >= 10000);
                     //bet really justneeds to be greater than precision which is 100 in this case//
                     address pool = IPoolF.getPool(token);
                     require(pool!=address(0), "Not a valid pool");
                     require(IERC20(token).balanceOf(msg.sender)>bet, 'Balance too low');
                     bool xfer = LINK.transferFrom(msg.sender, address(this), fee);
                     require(xfer , 'transfer of link failed');
                     bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
                     IPool = IHPool(pool);
                     IPool.commit(msg.sender, bet, b, edge, requestId);
                     games[requestId] = game(b, pool);
            }

            /**
            * Callback function used by VRF Coordinator
            */
            function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
                    IPool = IHPool(games[requestId].pool); 
                    if (BONE > randomness.mod(BONE.add(games[requestId].b))) IPool.payout(requestId);
                    //IPool.clear(requestId);
            }

}
