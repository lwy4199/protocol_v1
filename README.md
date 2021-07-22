Develop gunpool-V1 base on aave, function: deposit/withdraw/get reward from pcoin

    1. constructor funcion
       initReserve(): you can use this function that configure reserve/plane context,
                      especially gunpool-tokens


    2. configure function(can be done by owner)
       resetPcoinReward(): reset pcoin reward parameters;
       resetPlane(): reset base plane and gp-token address;
       setPcoinAddress(): set polylend token ERC20 address;
       pause(): set reserve pause/work;
       setFeeto(): set feeto account and permillage;
       getDepositAPY(): get APY by deposit

    3. service function
       deposit(): deposit amount for valid token, you will get reward by APY from plane;
       withdraw(): withdraw amount from valid token which belongs to you;
       claim(): you can receive rewards from pcoin
       rewardBalanceOf(): you can quary rewards from pcoin
       getDepositAccounts(): you can quary the number of deposit account

Future gunpool-Vxxx will base on other plane
