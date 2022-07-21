//remix ethers script to approve
(async () => {
    try {
        console.log('Running aprrove script...')
    
        const contractName = 'ERC20Token' 

        const artifactsPath = `browser/contracts/artifacts/${contractName}.json` 
    
        const metadata = JSON.parse(await remix.call('fileManager', 'getFile', artifactsPath))
        const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner()
    
        let rext = new ethers.Contract("0x1d229c1278b16c2089765178d477FAC44416fF31", metadata.abi, signer);
        let sct = new ethers.Contract("0x9746b8825AB2C2eb000A45b39dec588dE1b8752D", metadata.abi, signer);
        let rex = new ethers.Contract("0x43064d0BC8429E8880e06f97d8E9160Ef1bc51E4", metadata.abi, signer);

        let flashProvider = "0x10B67ae672663907e6A54c33EcB367Ab6e86209b";
        rext.approve(flashProvider, 100**7);
        sct.approve(flashProvider, 100**18);
        rex.approve(flashProvider, 5 * 10**7);
    
    } catch (e) {
        console.log(e.message)
    }
})()