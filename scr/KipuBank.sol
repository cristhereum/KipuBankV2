//0x694AA1769357215DE4FAC081bf1f309aDC325306 Ethereum ETH/USD
//0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 USDC Sepolia

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


/*///////////////////////
        Imports
///////////////////////*/
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*///////////////////////
        Libraries
///////////////////////*/
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
    address constant feed = address(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    address constant usdc = address(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);


    struct Balances {
      uint256 eth;
      uint256 usdc;
      uint256 total;
    }

    mapping (address => Balances) public balance;


    /*///////////////////////
    Errors
    ///////////////////////*/
    ///@notice error emitido cuando una transacción falla
    error TransactionFailed(bytes error);
    ///@notice error emitido cuando el retorno del oráculo es incorrecto
    error OracleCompromised();
    ///@notice error emitido cuando se intenta transferir cero
    error ZeroTransfer();
    ///@notice error emitido cuando "You dont have USDC"
    error NotEnoughUSDC();

    constructor(address _feed, address _usdc, address _owner) Ownable(_owner) {
      USDC = IERC20(_usdc);
      dataFeed = AggregatorV3Interface(_feed);
    }

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

    function depositETH() external payable {
      // Bajo a memoria lo que me mandan
      uint256 _amount = msg.value;

      // Chequeo que sea mayor que cero
      if (_amount > 0) {
        balance[msg.sender].eth += msg.value;
      }
      else revert ZeroTransfer();

      // Obtengo el precio del usdc
      uint256 _usdc = convertEthInUSD(_amount);

      balance[msg.sender].total += _usdc;

      // TODO: Emitir

    }

    function depositUSDC(uint256 _amount) external {
      
      // Antes que nada veo que tenga el token
      // Para no usar require(IERC20(USDC).balanceOf(msg.sender) > 0, "You dont have USDC");

      uint256 _usdcBalance = IERC20(USDC).balanceOf(msg.sender);
      if (_usdcBalance == 0)
      revert NotEnoughUSDC();
      
      // Después tengo que ver si tengo el allowance
      // require(IERC20(USDC).allowance(msg.sender, address(this)) > 0, "You need to aprove");
      uint256 allowance = IERC20(USDC).allowance(msg.sender, address(this));
      if(allowance < _amount)
      revert(); //TODO Error
      // Si no lo tengo lo tengo que aprobar
      IERC20(USDC).approve(address(this), _amount);

      // Actualizo el balance
      balance[msg.sender].usdc+= _amount;
      balance[msg.sender].total+= _amount;

      // TODO: Emitir el evento
      
      // Si lo tengo, lo transfiero
      IERC20(USDC).transferFrom(msg.sender, address(this), _amount);
      
      
    }


    function withdraw() public {
      // uint256 ethBalance = address(this).balance;
      uint256 ethBalance = balance[msg.sender].eth;
      // uint256 usdcBalance = i_usdc.balanceOf(address(this));
      uint256 usdcBalance = balance[msg.sender].usdc;

      if (ethBalance > 0) {
        // TODO: emit DonationsV2_SaqueRealizado(msg.sender, ethBalance);
            _transferEth(ethBalance);
      }
      if (usdcBalance > 0) {
        // TODO: emit DonationsV2_SaqueRealizado(msg.sender, usdcBalance);
          USDC.safeTransfer(msg.sender, usdcBalance);
        }

    }
    // function getMyBalance() public {}
    // function _getUSDCPrice() private {}



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
    
    if (_ethUSDPrice == 0) revert OracleCompromised();
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
        (bool success, bytes memory error) = msg.sender.call{value: _valor}("");
        if (!success) revert TransactionFailed(error);
    }


}


