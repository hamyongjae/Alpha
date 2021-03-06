pragma solidity ^0.4.24;

//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Game /*is usingOraclize*/ {

    /*
        dice values : uint8;
        number of players, addresses : uint8
        number of lands, landid : uint16
        amount of cash : uint32
    */

    uint id;
    address bj;
    uint8 N;
    uint8 M;
    uint8 playermin;
    uint8 playermax;
    uint8 dicemin;
    uint8 dicemax;
    
    
    // length : numplayers
    // key : address
    uint8 public numDone;
    address[] players;
    mapping(address => uint8) public addrids;
    mapping(address => uint8[2]) public poses;
    mapping(address => uint32) public cashes;
    mapping(address => uint8) public camefroms;
    mapping(address => uint8) public dices;
    
    // length : numlands
    // key : landid(uint16)
    uint32[] public prices;
    address[] public owners;
    uint16[] public built;
    uint32[] public highest_bid;
    address[] public highest_bidder;    
    
    uint16 constant wall = 65535;
    uint16[][] public board;   
    
    
    
    event GameEvent(uint indexed type_,address indexed addr);
    /*
        Dicegen = 0 , address(this)
        
        StartFail = 1 , address(this)
        
        JoinSuccess = 2 , playeraddr
        
        JoinFail = 3 , playeraddr 
        
        MoveSuccess = 5, playeraddr
        
        MoveFail = 6 , playeraddr
    
    */
    
    // constructor(uint id_, address bj_ ,uint8[] info, uint[] walls, uint32[] prices_) public{
    constructor() public{
        uint id_ = 3;
        address bj_ = 0x229dAe485C553355e1d6dA1180337B4809882092;
        uint32[36] memory prices_;
        for(uint a = 0;a<36;a++){
            prices_[a] = uint32(20000+((7**a)%9)*3000);
        }
        
        uint8[6] memory info = [10,10,1,10,1,10];
        uint[1] memory walls = [115735715935073412955811846413561534266942729113775074927116030918558482432000];
        
    
        
        id = id_;
        bj = bj_;
        prices = prices_;
        
        N = info[0];
        M = info[1];
        playermin = info[2];
        playermax = info[3];
        dicemin = info[4];
        dicemax = info[5];
        
        players.push(bj);
        cashes[bj] = 1000000;
        
        uint16[][] memory board_;
        board_ = new uint16[][](M);
        
        
        owners = new address[](prices.length);
        built = new uint16[](prices.length);
        highest_bid = new uint32[](prices.length);
        highest_bidder = new address[](prices.length);    
        
        
        uint8 cursor = 0;
        uint8 wallsindex = 0;
        
        uint16 landindex = 0;


        for (uint i = 0; i < M ; i++) {
            board_[i] = new uint16[](N);
            
            for(uint j = 0; j < N ; j++){
                
                uint curbit = uint(1) << uint8(255-cursor);
            
                
                if( (walls[wallsindex]&curbit) > 0 ){
                    board_[i][j] = landindex;
                    landindex++;
                }else{
                    board_[i][j] = wall;
                }
                
                
                if(cursor >= uint8(255) ){
                    cursor = uint8(0);
                    wallsindex = uint8(wallsindex+1);
                }else{
                    cursor = uint8(cursor+1);
                }
            }
            
            
        }
        
        board = board_;
    }
    
    function v_prices() public view returns (uint32[]){
        uint32[] memory result = prices;
        return result;
    }
    function v_viewrow(uint i) public view returns (uint16[]){
        return (board[i]); 
    }
    function v_dices() public view returns (uint8[] dices_){
        dices_ = new uint8[](players.length);
        for(uint i = 0; i < players.length; i++){
            dices_[i] = dices[players[i]];
        }
    }

    
   
    function start() public{
        if(true){
            gen_dices();
        }else{
            emit GameEvent(1,address(0));
        }
    }    
    function join() public{
        join_i(msg.sender);
    }
    
    
    function sum_moves_i() public{
        sum_moves();
    }
    
    
    function join_i(address sender) public{
        if(players.length<playermax && cashes[sender] == 0){
            cashes[sender] = 1000000;
            players.push(sender);
            emit GameEvent(2,sender);
        }else{
            emit GameEvent(3,sender);
        }
    }
      
    function action(uint8[] actionids, uint[] params) public{
        action_i(actionids,params,msg.sender);
    }
    function action_i(uint8[] actionids, uint[] params, address sender) public{
        if(dices[sender] == 0){
            emit GameEvent(21,sender);
        }
        
        for(uint i = 0; i < actionids.length; i++){
            uint8 actionid = actionids[i];
            
            if(actionid>=1&&actionid<=4){
                if(!ismovablelen(params[i])){
                    emit GameEvent(22,sender);
                    
                }
                
                uint8 val = uint8(params[i]);
                
                if(!move(sender,actionid,val)){
                    emit GameEvent(23,sender);
                    
                }
                
                
            }
            else if(actionid <= 7 && actionid >= 5){
                
                if(dices[sender] != 0){
                    emit GameEvent(18,sender);
                    
                }
                
                uint8[2] memory pos = poses[sender];
                uint16 landid = posToLandId(pos);
                    
                if(actionid == 5){ // bid
                    if(landid != wall){
                        uint32 bid = uint32(params[i]);
                        if(bid > highest_bid[landid]){
                            highest_bidder[landid] = sender;
                            highest_bid[landid] = bid;
                        }      
                    }
                    
                }else if(actionid == 6){ // sell
                    landid = uint16(params[i]);
                    if(owners[landid] == sender){
                        cashes[sender] += sellvalue(landid);
                        owners[landid] = address(0);
                    }
                }else if(actionid == 7){ // build
                    if(landid != wall){
                        built[landid] +=1;    
                    }
                }
            }
        }
        
        if(dices[sender] != 0){
            emit GameEvent(19,sender);
        }
        
        emit GameEvent(4,sender);
        
        numDone++;
        if(numDone == players.length){
            //sum_moves();
        }
    }
    
      
    function viewBoard() public view returns(address[] players_,uint[] cashes_, uint8[2][] poses_, address[] owners_ ,uint16[] buidings_){
        players_ = players;
        
        cashes_ = new uint[](players.length);
        poses_ = new uint8[2][](players.length);
        
        for(uint i = 0; i < players.length; i++){
            cashes_[i] = cashes[players[i]];
            poses_[i] = poses[players[i]];
        }
        
        owners_ = owners;
        buidings_ = built;
    }
    
    
    
    
    
    
    function gen_dices() internal{
        uint a = 37;
        for(uint i = 0; i<players.length ; i++){
            dices[players[i]] = uint8(a%(dicemax+1-dicemin)+dicemin);
            a *= 37;
        }
        emit GameEvent(0,address(0));
    }
    
    
    function sum_moves() internal{
        uint i = 0;
        // default moves
        // for(i = 0; i<players.length ; i++){
        //     if(dices[players[i]] > 0){
        //         default_action(players[i]);
        //     }
        // }
        
        // payments
        for(i = 0; i< players.length ; i++){
            address player = players[i];
            uint16 landid = posToLandId(poses[player]);
            if(owners[landid] != address(0) && owners[landid] != player){
                uint32 fee = calcFee(landid);
                if(cashes[player] >= fee||liquidate(player,fee-cashes[player])){
                    cashes[player] -= fee;
                    cashes[owners[landid]] += fee;
                }else{
                    // broke
                    cashes[owners[landid]] += cashes[player];
                    cashes[player] = 0;
                }
            }
        }
        
        
        // decide bidding winners;
        for(i = 0; i< prices.length ; i++){
            if(owners[i] == address(0) && highest_bidder[i] != address(0)){
                if(cashes[highest_bidder[i]]>highest_bid[i]){
                    cashes[highest_bidder[i]] -= highest_bid[i];
                    owners[i] = highest_bidder[i];
                    highest_bidder[i] = address(0);
                    highest_bid[i] = prices[i];
                }
            }
        }
        
        numDone = 0;
        gen_dices();
    }
    
    

    
    function liquidate(address addr,uint32 val) internal returns(bool){
        uint32 cum = 0;
        for(uint16 i = 0 ; i < prices.length ; i++){
            if(owners[i] == addr){
                uint32 sellval = sellvalue(i);
                cum += sellval;
                cashes[addr] += sellval;
                owners[i] = address(0);
                if(cum > val){
                    return true;    
                }
            }
        }
        return false;
    }
  
    
    function move(address addr, uint8 moveid, uint8 val) internal returns (bool){
        if(moveid == camefroms[addr]) return false;
        
        uint8 dice = dices[addr];
        uint8[2] memory pos = poses[addr];
        
        if(dice < val) val = dice;
        
        uint8 xVel = 0;
        uint8 yVel = 0;
        
        if(moveid == 1 || moveid ==3){
            xVel = uint8(moveid-2);
        }else{
            yVel = uint8(moveid-3);
        }
        
        uint8 count = 0;
        
        while(count<val){
            count = count+1;
            pos[0] += yVel;
            pos[1] += xVel;
            
            if(!inboard(pos)) return false;
            if(posToLandId(pos)==wall) return false;
        }
        
        dice -= val;
        
        dices[addr] = dice;
        poses[addr] = pos;
        camefroms[addr] = ((moveid-1)+2)%4 + 1;
        return true;
    }
    
    function default_action(address addr) internal{
        
        while(dices[addr]>0){
            for(uint8 moveid = 1; moveid<= 4 && moveid!=camefroms[addr]; moveid++){
                uint8 xVel = 0;
                uint8 yVel = 0;
                
                uint8[2] memory pos = poses[addr];
                
                if(moveid == 1 || moveid ==3){
                    xVel = uint8(moveid-2);
                }else{
                    yVel = uint8(moveid-3);
                }
                
                uint8 val = 0;
                bool isgood = true;
                
                while(isgood){
                    pos[0] += yVel;
                    pos[1] += xVel;
                    if(!inboard(pos)) isgood = false;
                    if(posToLandId(pos)==wall) isgood = false;
                    val++;
                }
                
                if(val>dices[addr])val = dices[addr];
                if(val != 0){
                    if(move(addr,moveid,val)) break;    
                } 
            }
        }
    }
    
        
    function calcFee(uint16 landid) internal view returns (uint32){
        return prices[landid]/uint8(10);
    }
    function sellvalue(uint16 landid) internal view returns (uint32){
        return prices[landid];
    }
    function inboard(uint8[2] pos) internal view returns(bool){
        return(pos[1]<N && pos[0]<M && pos[1]>=0 && pos[0]>=0);
    }
    function ismovablelen(uint val) internal view returns (bool){
        return (val>0 && val<dicemax);
    }
    function posToLandId(uint8[2] pos) internal view returns (uint16){
        return board[pos[0]][pos[1]];
    }

//   string public ETHUSD;
//   event LogConstructorInitiated(string nextStep);
//   event LogPriceUpdated(string price);
//   event LogNewOraclizeQuery(string description);

//   function __callback(bytes32 myid, string result) {
//       if (msg.sender != oraclize_cbAddress()) revert();
//       ETHUSD = result;
//       LogPriceUpdated(result);
//   }

//   function updatePrice() payable {
//       if (oraclize_getPrice("URL") > this.balance) {
//           LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
//       } else {
//           LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
//           oraclize_query("URL", "json(https://api.gdax.com/products/ETH-USD/ticker).price");
//       }
//   }
    
}