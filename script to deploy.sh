cast wallet import dayone --private-key 0xPK

forge create --broadcast src/contracts/ArtistTokenFactory.sol:ArtistTokenFactory \
  --rpc-url https://lens-mainnet.g.alchemy.com/v2/nX-ygP53hqHvxipRiWonF1twv26q5a6p \
  --account dayone \
  --verify


  forge create --broadcast \
  src/contracts/MockYieldPlatform.sol:MockYieldPlatform \
  --rpc-url https://lens-mainnet.g.alchemy.com/v2/nX-ygP53hqHvxipRiWonF1twv26q5a6p \
  --account dayone




    forge create --broadcast  \
  src/contracts/ArtistTokenFactory.sol:ArtistTokenFactory \
  --rpc-url https://lens-mainnet.g.alchemy.com/v2/nX-ygP53hqHvxipRiWonF1twv26q5a6p \
  --account dayone 


      forge create --broadcast  \
    src/contracts/actions/BuyArtistTokenAction.sol:BuyArtistTokenAction \
    --rpc-url https://lens-mainnet.g.alchemy.com/v2/nX-ygP53hqHvxipRiWonF1twv26q5a6p \
    --account dayone \
    --verify
forge create --broadcast  \
    src/contracts/actions/SellArtistTokenAction.sol:SellArtistTokenAction \
    --rpc-url https://lens-mainnet.g.alchemy.com/v2/nX-ygP53hqHvxipRiWonF1twv26q5a6p \
    --account dayone \
    --verify


forge create --broadcast src/contracts/PriceEngine.sol:PriceEngine \
  --rpc-url https://lens-mainnet.g.alchemy.com/v2/nX-ygP53hqHvxipRiWonF1twv26q5a6p \
  --account dayone \
  --verify

