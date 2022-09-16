pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    // 手续费收款账户
    address public feeTo;
    // 手续费设置账户
    address public feeToSetter;
    // tokenAaddress=>tokenBaddress=>pairAddress
    mapping(address => mapping(address => address)) public getPair;
    // 存储所有 pair
    address[] public allPairs;
    // 创建 pair的hash（此参数没有用到感觉没啥用）
bytes32 public INIT_CODE_HASH = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    
    constructor(address _feeToSetter) public {
        // 费用设置者
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        // 所有pair合约的个数
        return allPairs.length;
    }
        // 创建pair 合约
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 两个token不能相同
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        // 对两个token进行重新排序，数大的方后面
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // 判断数小的不能是零地址，
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        // 判断pair不能存在
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        // 获取pair合约的bytecode码
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // 以打包的两个token地址为不唯一的盐值
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            // 使用汇编 create2方法部署合约，
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // 使用pair合约的initialize 方法 传参 token0地址和 token1地址
        IUniswapV2Pair(pair).initialize(token0, token1);
        // 存储pair地址
        getPair[token0][token1] = pair;
        // 方便获取pair地址，
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        // pair地址push到总pair里
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
        // 设置 收取手续费的地址
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }
        // 设置 管理员地址
    function setFeeToSetter(address _feeToSetter) external {
        // 只允许管理员·设置管理员地址，这样的话设置完之后之前的管理员自动失效了
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
