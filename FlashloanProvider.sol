// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IFlashLoanProvider { 
    function executeFlashLoan(address callback, uint amount, address _token, bytes memory data) external;
}

// ------------------OPENZEPPELIN CONTRACTS---------------------------------------------
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//Every user who wishes to get a flashloan needs to implement 'FlashLoanUser' contract at their end. 
interface IFlashLoanUser { 
    function flashLoanCallback(uint amount, address token, bytes memory data) external;
}

//Provider of the flashloans
contract FlashLoanProvider is IFlashLoanProvider, ReentrancyGuard {
    mapping(address=>IERC20) public tokens;

    //the constructor takes the token addresses of the contract at the time of deployment, these tokens will be registered with the flashloan provider and the user can ask for flashloan for those tokens.
    constructor(address[] memory _tokens) {
        for(uint i = 0; i < _tokens.length; i++) {
            tokens[_tokens[i]] = IERC20(_tokens[i]);
        }
    }

    /** 
     *@dev This is the function to deposit some assets in our contract so that the flashloan can be provided to the user. 
     * Flashloan user doesn't have to call this or do anything related to depositing assets using this.
     * Approve flashloan provider with the amount of tokens first, then deposit.
     */
    function depositTokens(address[] memory tokens, uint256[] memory amounts) external {
        uint256 length = tokens.length;
        require(length == amounts.length, "invalid length");

        for(uint256 i = 0; i<length; i++){
            IERC20(tokens[i]).transferFrom(msg.sender, address(this), amounts[i]);
        }
    }

    /**
     * @dev This is the function which will be called by the flashloan user.
     * @param callback The address of th3e user contract which calls this method or where the assets have to be transferred.
     * @param amount the amount of token to be transferred.
     * @param _token the token which needs to be transferred.
     * @param data any data which is to be sent to the executor of flashloan at user's end. 
     */
    function executeFlashLoan(
        address callback,
        uint amount, 
        address _token, 
        bytes memory data
    ) external nonReentrant() override {
        IERC20 token = tokens[_token];
    
        uint originalBalance = token.balanceOf(address(this));

        require(address(token) != address(0), "token not supported.");
        require(originalBalance >= amount, "flash loan balance is not sufficient.");
        token.transfer(callback, amount);
        IFlashLoanUser(callback).flashLoanCallback(amount, _token, data);
        //fee set to 0% as of now
        require(token.balanceOf(address(this)) == originalBalance, "flash loan was not repaid.");

    }

    // to receive UZHETH
    receive() external payable {
        
    }
}