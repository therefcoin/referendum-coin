pragma solidity ^0.4.0;
contract ReferendumCoin {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        address delegate;
        address wallet;
        uint balanceOf;
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
    Proposal[] proposals;


    /// Create a new ballot with $(_numProposals) different proposals.
    function ReferendumCoin(uint8 _numProposals) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        voters[chairperson].balanceOf = totalSupply;
        proposals.length = _numProposals;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(voters[_from].balanceOf >= _value);
        // Check for overflows
        require(voters[_to].balanceOf + _value >= voters[_to].balanceOf);
        // Save this for an assertion in the future
        uint previousBalances = voters[_from].balanceOf + voters[_to].balanceOf;
        // Subtract from the sender
        voters[_from].balanceOf -= _value;
        // Add the same to the recipient
        voters[_to].balanceOf += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(voters[_from].balanceOf + voters[_to].balanceOf == previousBalances);
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
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
        if (msg.sender != chairperson ) {
            _transfer(chairperson,msg.sender,1);
        }
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
