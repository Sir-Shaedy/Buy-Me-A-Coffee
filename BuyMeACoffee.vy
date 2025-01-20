"""
@license MIT
pragma version 0.4.0
@title Buy Me A Coffee
@author Sir Shady 
"""

interface AggregatorV3Interface:  # Here is the ABI to call the live price
    def decimals() -> uint256: view
    def description() -> String[1000]: view
    def version() -> uint256: view
    def latestAnswer() -> int256: view

MINIMUM_USDT : public(constant(uint256)) = as_wei_value(5, "ether")
OWNER : public(immutable(address))
PRICE_FEED : public(immutable(AggregatorV3Interface)) # incase our smart contract is on a different blockchain, it must get the new BC address
funders : public(DynArray[address, 1000])
funder_To_Amount_Funded : public(HashMap[address, uint256]) #array to keep note of funders and funds

@deploy
def __init__(price_feed : address):
    PRICE_FEED = AggregatorV3Interface (price_feed)
    OWNER = msg.sender

@external
@payable 
def fund ():
    self._fund ()   

@internal
@payable  #for contracts to hold funds in then so we could read it later using view
def _fund():
    usd_value_of_eth : uint256 = self._get_Usdt_Eth_Price(msg.value)
    assert usd_value_of_eth >= MINIMUM_USDT, "You must spend more ETH!"  
    # to know how many funded us
    self.funders.append(msg.sender)
    self.funder_To_Amount_Funded[msg.sender] += msg.value

@external
def withdraw ():
    assert msg.sender == OWNER, " Not the contract owner"
    raw_call(OWNER, b"", value = self.balance)

    # resetting the list after withdraw
    for funder: address in self.funders:
        self.funder_To_Amount_Funded[funder] = 0
    self.funders = []
    
def set_Minimum ():
    pass

@internal
@view
def _get_Usdt_Eth_Price (eth_amount : uint256) -> uint256:
    eth_Price_Call : int256 = staticcall PRICE_FEED.latestAnswer () #320000000000 ... 8 digits
    eth_Dollar_Price_In_Wei : uint256 = (convert(eth_Price_Call, uint256)) * (10**10) #320000000000 * 10^10 .. 18 digits
    # the calls above are to get the usdt price of eth, then converted to wei
    # lets apply it. if james send more 2 eths, that'd be 2 * eth_dollar_price
    user_Eth_Price: uint256 = (eth_amount * eth_Dollar_Price_In_Wei) // (10**18)
    return user_Eth_Price

@external 
@view 
def get_Usdt_Eth_Price(eth_amount: uint256) -> uint256:
    return self._get_Usdt_Eth_Price(eth_amount)

@external
@payable
def __default__():
    self._fund()

# @external
#@view
#def get_Price () -> int256: # To get the price using chainlink address
 #   price_feed : AggregatorV3Interface = AggregatorV3Interface (0x694AA1769357215DE4FAC081bf1f309aDC325306)
 #   return staticcall price_feed.latestAnswer() # price feed will get the latest answer for the ethereum price
