cast wallet import lenskey --private-key 0xPK

forge create src/contracts/ArtistTokenFactory.sol:ArtistTokenFactory \
  --rpc-url https://rpc.testnet.lens.xyz \
  --constructor-args 0x7B744748Dd77eE149346D5FcA226A6276EfDDAeA \
  --account lenskey \
  --verify


  forge create --broadcast \
  src/contracts/MockYieldPlatform.sol:MockYieldPlatform \
  --rpc-url https://rpc.testnet.lens.xyz \
  --account lenskey \
  --constructor-args 0x7B744748Dd77eE149346D5FcA226A6276EfDDAeA --verify




    forge create \
  src/contracts/ArtistTokenFactory.sol:ArtistTokenFactory \
  --rpc-url https://rpc.testnet.lens.xyz \
  --account lenskey \
  --constructor-args 0x7B744748Dd77eE149346D5FcA226A6276EfDDAeA --verify


      forge create --broadcast  \
    src/contracts/actions/BuyArtistTokenAction.sol:BuyArtistTokenAction \
    --rpc-url https://rpc.testnet.lens.xyz \
    --account lenskey \
    --verify
forge create --broadcast  \
    src/contracts/actions/SellArtistTokenAction.sol:SellArtistTokenAction \
    --rpc-url https://rpc.testnet.lens.xyz \
    --account lenskey \
    --verify


forge create src/contracts/PriceEngine.sol:PriceEngine \
  --constructor-args $(cast abi-encode "constructor(address,address)" "0xA3091E53d1De939d0Ee9ab762946f27B35bEd3E8,0x7B744748Dd77eE149346D5FcA226A6276EfDDAeA") \
  --rpc-url https://rpc.testnet.lens.xyz \
  --account lenskey \
  --verify

