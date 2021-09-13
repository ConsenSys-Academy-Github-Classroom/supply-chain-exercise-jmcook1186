// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;
  uint public skuCount;
  mapping (uint => Item) items;
  enum State{ForSale, Sold, Shipped, Received}
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;

  }

  /* 
   * Events
   */

  event LogForSale (uint _sku);
  event LogSold (uint _sku);
  event LogShipped (uint _sku);
  event LogReceived (uint _sku);

  /* 
   * Modifiers
   */

  modifier isOwner(){
    require(owner == msg.sender);
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    address payable buyer = items[_sku].buyer;
    buyer.transfer(amountToRefund);
  }


  modifier forSale(uint _sku){
    // 0 = enum ForSale
    require(items[_sku].state== State.ForSale);
    require(items[_sku].buyer==address(0));
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state==State.Sold);
    require(items[_sku].buyer!=address(0));
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state==State.Shipped);
    require(items[_sku].buyer!=address(0));
    _;
  } 

  modifier received(uint _sku) {
    require(items[_sku].state==State.Received);
    require(items[_sku].buyer!=address(0));
    _;
  }


  constructor() public {
    owner = msg.sender;
    skuCount = 0;

  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    
    items[skuCount] = Item({
      name:_name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    });

    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(msg.value) checkValue(sku) {

    address payable seller = items[sku].seller;
    seller.transfer(items[sku].price);
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;
    emit LogSold(sku);

  }


  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller){

    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }



  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(sku);

  }

 
  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer){ 

     name = items[_sku].name; 
     sku = items[_sku].sku; 
     price = items[_sku].price; 
     state = uint(items[_sku].state); 
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer);

}

}
