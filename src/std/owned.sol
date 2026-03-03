// From ethereum/mix stdc/std.sol
// Standard "owned" contract - sets deployer as owner with setOwner transfer

contract owned {
    function owned() {
        owner = msg.sender;
    }
    modifier onlyowner() {
        if (msg.sender == owner) _
    }
    function setOwner(address _owner) onlyowner {
        owner = _owner;
    }
    address owner;
}
