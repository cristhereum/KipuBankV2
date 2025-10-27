//0x694AA1769357215DE4FAC081bf1f309aDC325306 Ethereum ETH/USD
//0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 USDC Sepolia

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


/*///////////////////////
        Imports
///////////////////////*/
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*///////////////////////
        Interfaces
///////////////////////*/
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title KipubankV2
 * @author cristhereum
 * @notice This is educational only.
 * @custom:security Do not use in production.
 */
contract KipuBank is Ownable{

    using SafeERC20 for IERC20;
    ///@notice variable constante para almacenar el factor de decimales
    uint256 constant DECIMAL_FACTOR = 1 * 10 ** 20;
    uint256 constant DECIMAL_FACTOR_2 = 1 * 10 ** 18;


    //@notice variable para el feed del precio del usdc
    AggregatorV3Interface internal dataFeed;

    IERC20 public USDC; // USDC
    // address constant feed = address(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    // address constant usdc = address(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);
    // address private _owner; // Variable para almacenar la dirección del propietario

    //@notice estructura de balances
    struct Balances {
      uint256 eth;
      uint256 usdc;
      uint256 total;
    }
    //@notice mapeo de estructuras de balances
    mapping (address => Balances) public balance;

    /*///////////////////////
    Eventos
    ////////////////////////*/
    ///@notice evento emitido cuando se realiza un deposito de ETH
    event DepositedETH(address sender, uint256 valor);
    ///@notice evento emitido cuando se realiza un deposito de USDC
    event DepositedUSDC(address sender, uint256 valor);
    ///@notice evento emitido cuando se realiza un retiro
    event Withdrawed(address receiver);


    /*///////////////////////
    Errors
    ///////////////////////*/
    ///@notice error emitido cuando una transacción falla
    error TransactionFailed(bytes err);
    ///@notice error emitido cuando el retorno del oráculo es incorrecto
    error OracleCompromised();
    ///@notice error emitido cuando se intenta transferir cero
    error ZeroTransfer();
    ///@notice error emitido cuando "You dont have USDC"
    error NotEnoughUSDC();
    ///@notice error emitido cuando no hay permiso de allow
    error NotEnoughAllowance();

    /*///////////////////////
        Constructor
    ///////////////////////*/
    constructor(address _feed, address _usdc) Ownable(msg.sender) {
        USDC = IERC20(_usdc);
        dataFeed = AggregatorV3Interface(_feed);
    }

    // constructor(address _feed, address _usdc) Ownable(_owner) {
    //   USDC = IERC20(_usdc);
    //   dataFeed = AggregatorV3Interface(_feed);
    //   _owner = msg.sender;
      
    // }
    

    // function deposit(uint256 _usdc, address _addr) external payable {

    //   uint256 _amount = msg.value;

    //   if (_addr == address(0)) // Transfiere ETH
    //     {balance[msg.sender].eth += msg.value;}
    //   else { // Transfiere TOKEN
    //     IERC20(_addr).transferFrom(msg.sender, address(this),_usdc);
    //   }

    //   if (_usdc > 0) {
    //     IERC20(_addr).transferFrom(msg.sender, address(this), _usdc);
    //   }
      
    //   // Obtengo el precio del usdc
    //   int256 _usdcPrice = getChainlinkDataFeedLatestAnswer();
    //   uint256 _usdc = ((_amount)*uint256(_usdcPrice)) / DECIMAL_FACTOR_2; //10**18;
    
    //   balance[msg.sender].total += _usdc;


    // }


    /*///////////////////////
        Deposit ETH
    ///////////////////////*/
    // * @notice función para depositar ETH
    // * @dev 
    function depositETH() external payable {
        uint256 _amount = msg.value;
        address _sender = msg.sender;
        // Chequeo que no sea una transferencia de cero
        if (_amount == 0) revert ZeroTransfer();
        
        // Effects
        balance[_sender].eth += _amount;

        uint256 _usdc = convertEthInUSD(_amount);
        balance[_sender].total += _usdc;

        // Evento
        emit DepositedETH(_sender, _amount);
    }

    /*///////////////////////
        Deposit USDC
    ///////////////////////*/
    // * @notice función para depositar USDC
    // * @dev 
    function depositUSDC(uint256 _amount) external {
        address _sender = msg.sender;
        // CHECKS
        // Chequeo que la transferencia no sea cero
        if (_amount == 0) revert ZeroTransfer();
        
        // Antes que nada veo que tenga el token
        uint256 _usdcBalance = IERC20(USDC).balanceOf(_sender);
        if (_usdcBalance < _amount) revert NotEnoughUSDC();

        // Después tengo que ver si tengo el allowance
        uint256 allowance = IERC20(USDC).allowance(_sender, address(this));
        if (allowance < _amount) revert NotEnoughAllowance();
        // EFFECTS
        // Actualizo balances
        balance[_sender].usdc += _amount;
        balance[_sender].total += _amount;

        // ITERACTIONS
        // Transferencia real del token
        IERC20(USDC).safeTransferFrom(_sender, address(this), _amount);

        // Evento
        emit DepositedUSDC(_sender, _amount);
    }



    /*///////////////////////
        Withdraw
    ///////////////////////*/
    // * @notice función para retirar los fondos
    // * @dev 
    function withdraw() external {
        address _sender = msg.sender;
        uint256 ethBalance = balance[_sender].eth;
        uint256 usdcBalance = balance[_sender].usdc;

        if (ethBalance > 0) {
            balance[_sender].eth = 0;
            _transferEth(ethBalance);
        }

        if (usdcBalance > 0) {
            balance[_sender].usdc = 0;
            USDC.safeTransfer(_sender, usdcBalance);
        }

        balance[_sender].total = 0;

        emit Withdrawed(_sender);
    }

    // }
    // function getMyBalance() public {}
    // function _getUSDCPrice() private {}

    /*///////////////////////
        Oracle & Conversion
    ///////////////////////*/

    // * @notice función para consultar el precio en USD del ETH
    // * @return ethUSDPrice_ el precio provisto por el oráculo.
    // * @dev esta es una implementación simplificada, y no sigue completamente las buenas prácticas
    // function chainlinkFeed() internal view returns (uint256 ethUSDPrice_) {
    function getChainlinkDataFeedLatestAnswer() internal view returns (int256 _ethUSDPrice) {
    (
      /* uint80 roundId */,
      _ethUSDPrice,
      /*uint256 startedAt*/,
      /*uint256 updatedAt*/,
      /*uint80 answeredInRound*/
    ) = dataFeed.latestRoundData();
    
    if (_ethUSDPrice <= 0) revert OracleCompromised();
    return _ethUSDPrice;
  }

    /**
    * @notice función interna para realizar la conversión de decimales de ETH a USDC
     * @param _ethAmount la cantidad de ETH a ser convertida
     * @return convertedAmount_ el resultado del cálculo.
     */
    function convertEthInUSD(uint256 _ethAmount) internal view returns (uint256 convertedAmount_) {
        uint256 _usdcPrice = uint256(getChainlinkDataFeedLatestAnswer());
        convertedAmount_ = (_ethAmount * _usdcPrice) / DECIMAL_FACTOR_2; //10**18;
    }


    /**
     * @notice función privada para realizar la transferencia de ether
     * @param _valor El valor a ser transferido
     * @dev necesita revertir si falla
     */
    function _transferEth(uint256 _valor) private {
        (bool success, bytes memory err) = msg.sender.call{value: _valor}("");
        if (!success) revert TransactionFailed(err);
    }



}


