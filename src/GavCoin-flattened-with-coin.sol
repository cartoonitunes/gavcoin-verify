contract owned {
    function owned() { owner = msg.sender; }
    modifier onlyowner { if(msg.sender==owner) _ }
    function setOwner(address _owner) onlyowner { owner = _owner; }
    address owner;
}

contract named {
    function named(bytes32 _name) {
        NameReg(0x084f6a99003dae6d3906664fdbf43dd09930d0e3).register(_name);
    }
    function name() constant returns (address) {
        return NameReg(0x084f6a99003dae6d3906664fdbf43dd09930d0e3);
    }
}

contract NameReg { function addressOf(bytes32 _name) constant returns (address) {} function register(bytes32 _name) {} }

contract coin { uint tota; }

contract Coin {
    function sendCoinFrom(address _from, uint _val, address _to);
    function sendCoin(uint _val, address _to);
    function coinBalance() constant returns (uint _r);
    function coinBalanceOf(address _a) constant returns (uint _r);
    function approve(address _a);
    function isApproved(address _proxy) constant returns (bool _r);
    function isApprovedFor(address _target, address _proxy) constant returns (bool _r);
}

contract BasicCoin is Coin {
    function sendCoinFrom(address _from, uint _val, address _to) {
        if (m_balances[_from] >= _val && m_approved[_from][msg.sender]) {
            m_balances[_from] -= _val;
            m_balances[_to] += _val;
            log3(sha3(_val), 0, sha3(_from), sha3(_to));
        }
    }
    function sendCoin(uint _val, address _to) {
        if (m_balances[msg.sender] >= _val) {
            m_balances[msg.sender] -= _val;
            m_balances[_to] += _val;
            log3(sha3(_val), 0, sha3(msg.sender), sha3(_to));
        }
    }
    function coinBalance() constant returns (uint _r) { return m_balances[msg.sender]; }
    function coinBalanceOf(address _a) constant returns (uint _r) { return m_balances[_a]; }
    function approve(address _a) {
        m_approved[msg.sender][_a] = true;
        log3(0, 1, sha3(msg.sender), sha3(_a));
    }
    function isApproved(address _proxy) constant returns (bool _r) { return m_approved[msg.sender][_proxy]; }
    function isApprovedFor(address _target, address _proxy) constant returns (bool _r) { return m_approved[_target][_proxy]; }
    mapping (address => uint) m_balances;
    mapping (address => mapping (address => bool)) m_approved;
}

contract GavCoin is BasicCoin, named("GavCoin"), coin, owned {
    function GavCoin() {
        m_balances[owner] = tota;
        m_lastNumberMined = block.number;
    }
    function mine() {
        uint r = block.number - m_lastNumberMined;
        if (r > 0) {
            log2(sha3(r * 1000), 2, sha3(msg.sender));
            log2(sha3(r * 1000), 3, sha3(block.coinbase));
            m_balances[msg.sender] += 1000 * r;
            m_balances[block.coinbase] += 1000 * r;
            m_lastNumberMined = block.number;
        }
    }
    uint m_lastNumberMined;
}
