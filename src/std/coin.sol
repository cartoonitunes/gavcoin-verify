// Reconstructed from bytecode analysis and dapp-bin source
// The "coin" base contract was a parameterized contract that set token metadata
//
// coin("GAV", 1000) would set:
//   - symbol/name to "GAV"
//   - denomination to 1000 (1000 raw units = 1 display unit)
//   - tota = 0 (initial total supply, all comes from mining)
//
// From the GavCoin constructor: m_balances[owner] = tota;
// Since GavCoin has no pre-mine (all supply comes from mine()), tota is likely 0.
//
// The denomination of 1000 means: 1 GAV = 1000 raw units.
// The mine() function mints 1000 * blocksSinceLastMine raw units = blocksSinceLastMine GAV.
//
// NOTE: This is a reconstruction. The exact implementation may have differed.

contract coin {
    function coin(bytes32 _symbol, uint _denomination) {
        sym = _symbol;
        denom = _denomination;
        tota = 0;
    }
    bytes32 sym;
    uint denom;
    uint tota;
}
