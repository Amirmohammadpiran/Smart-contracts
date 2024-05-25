# How to mint an NFT
## in opensea.testnets

1- Create account in this website:
	https://console.filebase.com/

2- Create bucket and add the media of NFT, add a metadata.json which includes the IPFS gateway URL of the media and info about NFT like this:
	
	```{ 
	  "description": "my first f***ing nft!",
	  "external_url": "Alchemy.com/?a=roadtoweb3weekone",
	  "image": "https://ipfs.filebase.io/ipfs/QmcPtQdBDN2sZSTCMjVTusso7LS1R21emEVb1uNRLtUF43",
	  "name": "A cool NFT", 
	  "attributes": [
	    {
	      "trait_type": "Power", 
	      "value": "Science"
	    }, 
	    {
	      "trait_type": "Series", 
	      "value": "Family Guy"
	    }]
	}```


3- Copy the CID of the metadata as the token URL.

4- Get some free Sepolia ETH from here:
	https://faucets.chain.link/sepolia

5- Connect the web Remix to metamask

6- Take the testnet.opensea wallet ID

7- Deploy and run the contract (wallet and token URL)

The NFT will be exposed on the website!
