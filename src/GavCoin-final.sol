contract NameReg {
    function addressOf(bytes32 _name) constant returns (address addr) {}
    function register(bytes32 _name) {}
}

contract GavCoin {
    mapping (address => uint) m_balances;
    mapping (address => mapping (address => bool)) m_approved;
    address owner;
    uint m_lastNumberMined;

    function GavCoin() {
        NameReg(nameRegAddress()).register("GavCoin");
        owner = msg.sender;
        m_balances[msg.sender] = 1000000;
        m_lastNumberMined = block.number;
    }

    function named(bytes32 _name) constant returns (address) {
        return NameReg(nameRegAddress()).addressOf(_name);
    }

    function nameRegAddress() constant returns (address) {
        return 0x084f6a99003dae6d3906664fdbf43dd09930d0e3;
    }

    function sendCoinFrom(address _from, uint _val, address _to) {
        if (m_balances[_from] >= _val && m_approved[_from][msg.sender]) {
            m_balances[_from] -= _val;
            m_balances[_to] += _val;
        }
    }
    function sendCoin(uint _val, address _to) {
        if (m_balances[msg.sender] >= _val) {
            m_balances[msg.sender] -= _val;
            m_balances[_to] += _val;
        }
    }
    function coinBalance() constant returns (uint _r) { return m_balances[msg.sender]; }
    function coinBalanceOf(address _a) constant returns (uint _r) { return m_balances[_a]; }
    function approve(address _a) {
        m_approved[msg.sender][_a] = true;
    }
    function isApproved(address _proxy) constant returns (bool _r) { return m_approved[msg.sender][_proxy]; }
    function isApprovedFor(address _target, address _proxy) constant returns (bool _r) { return m_approved[_target][_proxy]; }

    function mine() {
        uint r = block.number - m_lastNumberMined;
        if (r > 0) {
            m_balances[msg.sender] += 1000 * r;
            m_balances[block.coinbase] += 1000 * r;
            m_lastNumberMined = block.number;
        }
    }

    function changeOwner(address _owner) { if(msg.sender==owner) owner = _owner; }
}
