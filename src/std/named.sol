// Reconstructed from bytecode analysis of GavCoin contract
// The "named" base contract registers a name with the NameReg and provides lookup functions
//
// Bytecode evidence:
//   - Constructor calls NameReg.register(bytes32) at 0x084f6a99003dae6d3906664fdbf43dd09930d0e3
//   - Exposes name() -> returns bytes32 (selector 0x06005754)
//   - Exposes named(bytes32) -> calls NameReg.addressOf(bytes32) (selector 0xa550f86d)
//
// The NameReg address 0x084f6a99003dae6d3906664fdbf43dd09930d0e3 was the live NameReg
// on mainnet at the time of deployment (registered in the Config contract).
//
// NOTE: The exact implementation below is a reconstruction. The original was part of
// the Mix IDE preprocessor system and may have had slightly different structure.

contract NameReg {
    function addressOf(bytes32 _name) constant returns (address addr) {}
    function register(bytes32 _name) {}
}

contract named {
    function named(bytes32 _name) {
        NameReg(0x084f6a99003dae6d3906664fdbf43dd09930d0e3).register(_name);
    }

    function name() constant returns (bytes32) {
        return NameReg(0x084f6a99003dae6d3906664fdbf43dd09930d0e3);
    }

    function named(bytes32 _name) constant returns (address) {
        return NameReg(0x084f6a99003dae6d3906664fdbf43dd09930d0e3).addressOf(_name);
    }
}
