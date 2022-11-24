// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// File: contracts\open-zeppelin-contracts\SafeMath.sol

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}


// File: contracts\open-zeppelin-contracts\Context.sol

abstract contract Context {

    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this;
        return msg.data;
    }

}


// File: contracts\open-zeppelin-contracts\IBEP20.sol

interface IBEP20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);

    function decimals() external view returns(uint8);

    function symbol() external view returns(string memory);

    function name() external view returns(string memory);

    function getOwner() external view returns(address);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address _owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

}


// File: contracts\open-zeppelin-contracts\IUniswapV2Factory.sol

interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB) external returns(address pair);

}


// File: contracts\open-zeppelin-contracts\IUniswapV2Router01.sol

interface IUniswapV2Router01 {

    function factory() external pure returns(address);

    function WETH() external pure returns(address);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns(uint256 amountToken, uint256 amountETH, uint256 liquidity);

}


// File: contracts\open-zeppelin-contracts\IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}


// File: contracts\open-zeppelin-contracts\PancakePair.sol

interface PancakePair {

    function sync() external;

}


// File: contracts\open-zeppelin-contracts\Acetylene.sol

contract Acetylene is Context, IBEP20 {

    using SafeMath for uint256;

    address public pancakePair;
    address public DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 public pancakeRouter;

    mapping(address => uint256) private _balances;
    mapping(address => bool) public _isPair;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(uint256 => mapping(address => bool)) private pair_timeStamp_address_voted;
    mapping(uint256 => mapping(address => uint256)) private pair_value_to_weight;
    mapping(address => mapping(uint256 => uint256)) public balanceSubmittedForVoting;
    mapping(uint256 => mapping(address => bool)) private timeStamp_address_voted;
    mapping(uint256 => mapping(uint256 => uint256)) private value_to_weight;

    string private _symbol = "ACE";
    string private _name = "Acetylene";

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 21000000 * 10 ** 18;
    uint256 public votingThreshold = (_totalSupply * 5) / 1000;
    uint256 public liquidityPercentage = 5;
    uint256 public lastPairInteraction;
    uint256 public numberOfHoursToSleep = 48;
    uint256 private _deployedAt;
    uint256 multiplier = 999 ** 8;
    uint256 divider = 1000 ** 8;

    event SleepTimerTimestamp(uint256 indexed _timestamp);
    event pairVoteTimestamp(uint256 indexed _timestamp);

    constructor() {
        _balances[msg.sender] = _totalSupply;
        IUniswapV2Router02 _pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a uniswap pair for this new token
        pancakePair = IUniswapV2Factory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        lastPairInteraction = block.timestamp;
        _isPair[pancakePair] = true;
        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        _deployedAt = block.timestamp;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getOwner() external pure override returns(address) {
        return address(0);
    }

    function decimals() external view override returns(uint8) {
        return _decimals;
    }

    function symbol() external view override returns(string memory) {
        return _symbol;
    }

    function name() external view override returns(string memory) {
        return _name;
    }

    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns(uint256 _currentBalance) {
        return _balances[account];
    }

    function _updatedPairBalance(uint256 oldBalance) private returns(uint256) {
        uint256 balanceBefore = oldBalance;
        uint256 timePassed = block.timestamp - lastPairInteraction;
        uint256 power = (timePassed).div(3600); //3600: num of secs in 1 hour
        power = power <= numberOfHoursToSleep ? power : numberOfHoursToSleep;
        lastPairInteraction = power > 0 ? block.timestamp : lastPairInteraction;
        while (power > 8) {
            oldBalance = (oldBalance.mul(multiplier)).div(divider);
            power -= 8;
        }
        oldBalance = (oldBalance.mul(999 ** power)).div(1000 ** power);
        uint256 _toBurn = balanceBefore.sub(oldBalance);
        if (_toBurn > 0) {
            _balances[DEAD_ADDRESS] += _toBurn;
            emit Transfer(pancakePair, DEAD_ADDRESS, _toBurn);
        }
        return oldBalance;
    }

    function transfer(address recipient, uint256 amount) external override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        _balances[pancakePair] = _balances[pancakePair].add(tLiquidity);
        emit Transfer(sender, pancakePair, tLiquidity);
    }

    function claimVotingBalance(uint256 _timestamp, uint256 amount) external {
        require(amount > 0, "amount should be > 0");
        require(balanceSubmittedForVoting[msg.sender][_timestamp] >= amount, "requested amount more than voted amount");
        require(block.timestamp - _timestamp > 3600, "can only withdraw after round end");
        _balances[msg.sender] = _balances[msg.sender] + amount;
        balanceSubmittedForVoting[msg.sender][_timestamp] = balanceSubmittedForVoting[msg.sender][_timestamp].sub(amount);
        _balances[address(this)] = _balances[address(this)].sub(amount);
        require(_balances[msg.sender] <= getMaximumBalance(), "Balance exceeds threshold");
        emit Transfer(address(this), msg.sender, amount);
    }

    function voteForSleepTimer(uint256 timestamp, uint256 _value) external returns(uint256) {
        require(block.timestamp != timestamp, "sorry no bots");
        require(!timeStamp_address_voted[timestamp][msg.sender] || timestamp == 0, "Already voted!");
        require(_balances[msg.sender] >= votingThreshold, "non enough balance to vote");
        require(_value != numberOfHoursToSleep, "can't vote for same existing value");
        require(timestamp == 0 || (block.timestamp).sub(timestamp) <= 3600, "voting session closed");
        uint256 _timestamp = timestamp == 0 ? block.timestamp : timestamp;
        timeStamp_address_voted[_timestamp][msg.sender] = true;
        value_to_weight[_timestamp][_value] = value_to_weight[_timestamp][_value] + 1;
        _balances[msg.sender] = _balances[msg.sender] - votingThreshold;
        balanceSubmittedForVoting[msg.sender][timestamp] = balanceSubmittedForVoting[msg.sender][timestamp] + votingThreshold;
        _balances[address(this)] = _balances[address(this)] + votingThreshold;
        emit Transfer(msg.sender, address(this), votingThreshold);
        if (value_to_weight[_timestamp][_value] > 4) {
            numberOfHoursToSleep = _value;
            return 0;
        }
        emit SleepTimerTimestamp(_timestamp);
        return _timestamp;
    }

    function voteForPair(uint256 timestamp, address _value) external returns(uint256) {
        require(block.timestamp != timestamp, "sorry no bots");
        require(!pair_timeStamp_address_voted[timestamp][msg.sender] || timestamp == 0, "Already voted!");
        require(_balances[msg.sender] >= votingThreshold, "non enough balance to vote");
        require(!_isPair[_value], "address already declared as pair");
        require(timestamp == 0 || (block.timestamp).sub(timestamp) <= 3600, "voting session closed");
        uint256 _timestamp = timestamp == 0 ? block.timestamp : timestamp;
        pair_timeStamp_address_voted[_timestamp][msg.sender] = true;
        pair_value_to_weight[_timestamp][_value] = pair_value_to_weight[_timestamp][_value] + 1;
        _balances[msg.sender] = _balances[msg.sender] - votingThreshold;
        balanceSubmittedForVoting[msg.sender][timestamp] = balanceSubmittedForVoting[msg.sender][timestamp] + votingThreshold;
        _balances[address(this)] = _balances[address(this)] + votingThreshold;
        emit Transfer(msg.sender, address(this), votingThreshold);
        if (pair_value_to_weight[_timestamp][_value] > 4) {
            _isPair[_value] = true;
            return 0;
        }
        emit pairVoteTimestamp(_timestamp);
        return _timestamp;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        uint256 tLiquidity;
        if (sender == pancakePair || recipient == pancakePair) {
            tLiquidity = amount.mul(liquidityPercentage).div(100);
        }
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount.sub(tLiquidity));
        require(_isPair[recipient] || _balances[recipient] <= getMaximumBalance(), "Balance exceeds threshold");
        _takeLiquidity(sender, tLiquidity);
        emit Transfer(sender, recipient, amount.sub(tLiquidity));
    }

    function getMaximumBalance() public view returns(uint256) {
        if (block.timestamp - _deployedAt >= 1209600) return _totalSupply;
        if (block.timestamp - _deployedAt >= 604800) return (_totalSupply * 15) / 1000;
        else return _totalSupply / 100;
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function updatePrice() external {
        require(block.timestamp - lastPairInteraction >= 3600, "One execution per hour");
        uint256 _pancakeBalance = _balances[pancakePair];
        _balances[pancakePair] = _updatedPairBalance(_pancakeBalance);
        PancakePair(pancakePair).sync();
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }

}
