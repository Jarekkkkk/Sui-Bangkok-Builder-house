# Sui-Bangkok-Builder-house

1. requester upload the document to Walrus that is to be signed and get the document CID and onchain object ID in the wallet
2. requester wrap the Blob object onchain and pre-paid the gas fee then send to the recipient through Zk-send
3. the recipient claimed the wrapped blob object then be redirected to app page
4. App page check their owned objects to see if there's and pending docs to be signed
5. if does, then we decompile all the blobs in the walrus and show all the docs in the app
6. signer can choose Sui NS/ or web2 proof ( with reclaim ) to sign the the document and save the verified on-chain
7. after siging, the wrapped object will be sent back the sender
