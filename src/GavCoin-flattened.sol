// Flattened GavCoin contract - all base contracts inlined
// Original source: https://github.com/ethereum/dapp-bin/blob/master/coin/coin.sol
// Standard library: https://github.com/ethereum/mix/tree/master/stdc
//
// This is a reconstruction of what the #require preprocessor would have produced.
// The exact output depends on how the preprocessor resolved and inlined contracts.
//
// IMPORTANT: This file needs iteration to match the on-chain bytecode.
// The base contracts (named, owned, coin) are reconstructed from bytecode analysis
// and may need adjustments to their exact structure.

// --- owned (from ethereum/mix stdc/std.sol) ---

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

// --- named (reconstructed from bytecode) ---

contract NameRegInterface {
    function addressOf(bytes32 _name) constant returns (address addr) {}
    function register(bytes32 _name) {}
}

contract named {
    function named(bytes32 _name) {
        NameRegInterface(0x084f6a99003dae6d3906664fdbf43dd09930d0e3).register(_name);
    }

    function name() constant returns (address) {
        return NameRegInterface(0x084f6a99003dae6d3906664fdbf43dd09930d0e3);
    }

    function named(bytes32 _name) constant returns (address) {
        return NameRegInterface(0x084f6a99003dae6d3906664fdbf43dd09930d0e3).addressOf(_name);
    }
}

// --- coin (reconstructed from bytecode) ---

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

// --- Coin interface (from dapp-bin) ---

contract Coin {
    function sendCoinFrom(address _from, uint _val, address _to);
    function sendCoin(uint _val, address _to);
    function coinBalance() constant returns (uint _r);
    function coinBalanceOf(address _a) constant returns (uint _r);
    function approve(address _a);
    function isApproved(address _proxy) constant returns (bool _r);
    function isApprovedFor(address _target, address _proxy) constant returns (bool _r);
}

// --- BasicCoin (from dapp-bin) ---

contract BasicCoin is Coin {
    function sendCoinFrom(address _from, uint _val, address _to) {
        if (m_balances[_from] >= _val && m_approved[_from][msg.sender]) {
            m_balances[_from] -= _val;
            m_balances[_to] += _val;
            log3(hash(_val), 0, hash(_from), hash(_to));
        }
    }

    function sendCoin(uint _val, address _to) {
        if (m_balances[msg.sender] >= _val) {
            m_balances[msg.sender] -= _val;
            m_balances[_to] += _val;
            log3(hash(_val), 0, hash(msg.sender), hash(_to));
        }
    }

    function coinBalance() constant returns (uint _r) {
        return m_balances[msg.sender];
    }

    function coinBalanceOf(address _a) constant returns (uint _r) {
        return m_balances[_a];
    }

    function approve(address _a) {
        m_approved[msg.sender][_a] = true;
        log3(0, 1, hash(msg.sender), hash(_a));
    }

    function isApproved(address _proxy) constant returns (bool _r) {
        return m_approved[msg.sender][_proxy];
    }

    function isApprovedFor(address _target, address _proxy) constant returns (bool _r) {
        return m_approved[_target][_proxy];
    }

    mapping (address => uint) m_balances;
    mapping (address => mapping (address => bool)) m_approved;
}

// --- GavCoin (from dapp-bin) ---

contract GavCoin is BasicCoin, named("GavCoin"), coin("GAV", 1000), owned {
    function GavCoin() {
        m_balances[owner] = tota;
        m_lastNumberMined = block.number;
    }

    function mine() {
        uint r = block.number - m_lastNumberMined;
        if (r > 0) {
            log2(hash(r * 1000), 2, hash(msg.sender));
            log2(hash(r * 1000), 3, hash(block.coinbase));
            m_balances[msg.sender] += 1000 * r;
            m_balances[block.coinbase] += 1000 * r;
            m_lastNumberMined = block.number;
        }
    }

    uint m_lastNumberMined;
}
