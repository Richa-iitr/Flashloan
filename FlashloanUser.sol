// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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

interface IFlashLoanUser { 
    function flashLoanCallback(uint amount, address token, bytes memory data) external;
}

interface IFlashLoanProvider { 
    function executeFlashLoan(address callback, uint amount, address _token, bytes memory data) external;
}

//This is the contract which is to be implemented by the flashloan user.
contract FlashLoanUser is IFlashLoanUser { 

    IFlashLoanProvider private provider; 

    /**
     * @dev function to take flashloan
     * @param _provider address of the flashloan provider
     * @param amount amount of token to be borrowed
     * @param _token address of the token to be borrowed
     */
    function startFlashLoan(
        address _provider, 
        uint amount, 
        address _token
    ) external { 
        provider = IFlashLoanProvider(_provider);
        provider.executeFlashLoan(address(this), amount, _token, bytes(''));
    }

    /**
     *@dev this mehtod is called by the flashloan provider once the assets are successfully tramsferred to the user.
     * This will contain the code for arbitrage or any other operation we need to do with the flashloan.
     * Once the operation is done, it will repay the loan amount back to the provider.
     */
    function flashLoanCallback(uint amount, address _token, bytes memory data) external override {
        require(msg.sender == address(provider), 'only flash loan provider can execute callback.');
        
        // perform arbitrage, liquidation etc in this function.

        IERC20(_token).transfer(address(provider), amount);
    }

}