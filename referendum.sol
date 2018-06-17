pragma solidity ^0.4.0;
contract ReferendumCoin {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 2;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    uint public referendum_start_date;
    uint public referendum_end_date;
    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        address delegate;
        address wallet;
        bool coin_received;
    }
    struct Proposal {
        uint voteCount;
    }

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    address chairperson;
    mapping(address => Voter) voters;
    mapping(address => uint) balances;
    Proposal[] proposals;


    /// Create a new ballot with $(_numProposals) different proposals.
    constructor(uint8 _numProposals,string _name,string _symbol,uint256 _totalSupply
                            ,uint _start,uint _end) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        totalSupply = _totalSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        name = _name;
        symbol = _symbol;
        balances[chairperson] = totalSupply;
        proposals.length = _numProposals;
        referendum_start_date = _start;
        referendum_end_date = _end;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value >= balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    /// Give $(toVoter) the right to vote on this ballot.
    /// May only be called by $(chairperson).
    
    function giveRightToVote(address toVoter) public {
        if (msg.sender != chairperson || voters[toVoter].voted) return;
        voters[toVoter].weight = 1;
    }

    /// Delegate your vote to the voter $(to).
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted) return;
        while (voters[to].delegate != address(0) && voters[to].delegate != msg.sender)
            to = voters[to].delegate;
        if (to == msg.sender) return;
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegateTo = voters[to];
        if (delegateTo.voted)
            proposals[delegateTo.vote].voteCount += sender.weight;
        else
            delegateTo.weight += sender.weight;
    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint8 toProposal) public {
        Voter storage sender = voters[msg.sender];
        if (sender.voted || toProposal >= proposals.length) return;
        if (now  < referendum_start_date || now > referendum_end_date ) return;
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
        if (msg.sender != chairperson ) {
            _transfer(chairperson,msg.sender,1);
        }
    }

    /// Give a single vote to proposal $(toProposal).
    function extend_referendum_date(uint new_date) public {
        if( chairperson != msg.sender) return;
        if(new_date <= referendum_end_date) return;//invalid date
        referendum_end_date = new_date;
        
    }

    function winningProposal() public constant returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }
    }
}
