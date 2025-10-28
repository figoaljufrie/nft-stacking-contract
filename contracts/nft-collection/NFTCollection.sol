//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

//standard ERC721 NFT Implementation from OpenZeppelin.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//Ownership control; Only Owner modifier allows restricted functions.
import "@openzeppelin/contracts/access/Ownable.sol";
//Protects payable functions from reentrancy attacks
import "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
//Burnable and enumerable extension for advanced NFT features.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

//note; URI = Uniform Resource Identifier -> points to a metadata in token / block-chain.
contract MyNFT is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ReentrancyGuardTransient,
    Ownable
{
    uint256 private _nextTokenId;
    mapping(uint256 => string) private _tokenURIs;
    string private _baseTokenURI;

    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        string tokenURI
    );

    uint256 public mintPrice;
    uint256 public constant MAX_SUPPLY = 10000; // Maximum NFT supply

    //to sets initial owner and starts tokenId at 1.
    //the constructor allows us to restrict functions, in this case: minting specific to owner only.
    constructor(
        address initialOwner
    ) ERC721("MyNFT", "MNFT") Ownable(initialOwner) {
        _nextTokenId = 1;
        mintPrice = 0; //default mint price = 0 (owner-only = free);
    }

    //sets base URI for all token URIs.
    //if sets, tokenURI = baseURI + token-specific URI.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    //sets minimal mintPrice.
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    //to mint new NFT to user's address.
    //Only owner can mint, emits NFTMinted for front-end tracking.
    function mint(
        address to,
        string memory tokenURI_
    ) external onlyOwner returns (uint256) {
        require(_nextTokenId <= MAX_SUPPLY, "Max supply reached");
        uint256 tid = _nextTokenId; // save current tokenId.
        _safeMint(to, tid); // mint safely (checks smart contracts receivers);
        _tokenURIs[tid] = tokenURI_; //store meta-data URI.
        _nextTokenId++; //Increment tokenId for next mint.
        emit NFTMinted(to, tid, tokenURI_); //emit event
        return tid; //return new token Id
    }

    //Public minting function for users.
    function mintPublic(
        string memory tokenURI_
    ) external payable nonReentrant returns (uint256) {
        //validation: if users mint, they must pay at least mintPrice. If not:
        require(msg.value >= mintPrice, "Insufficient funds to mint");
        require(_nextTokenId <= MAX_SUPPLY, "Max supply reached");
        //proceed minting if validation passed.
        uint256 tid = _nextTokenId;
        //msg.sender = user's wallet.
        _safeMint(msg.sender, tid);
        //store the meta-data URI.
        _tokenURIs[tid] = tokenURI_;
        //increment tokenId for next mint.
        _nextTokenId++;
        //emit event for front-end tracking.
        emit NFTMinted(msg.sender, tid, tokenURI_);
        return tid;
    }

    // Withdraw function for contract owner to collect funds
    function withdraw() external onlyOwner nonReentrant {
        //get contract balance:
        uint256 balance = address(this).balance;
        //validation: check if there are funds to withdraw.
        require(balance > 0, "No funds to withdraw");
        //transfer balance to owner's wallet using call pattern (safer)
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");
    }

    //returns the token URI for a given tokenId;
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        //validation: Token must exist, if not:
        require(ownerOf(tokenId) != address(0), "ERC721: token does not exist.");
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return
                bytes(_baseTokenURI).length > 0
                    ? string(abi.encodePacked(_baseTokenURI, _tokenURI))
                    : _tokenURI;
        }
        //fallback: use ERC721's tokenURI implementation.
        return super.tokenURI(tokenId);
    }

    // Override _update from both ERC721 and ERC721Enumerable
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    // Override _increaseBalance from both ERC721 and ERC721Enumerable
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
