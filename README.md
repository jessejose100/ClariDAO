# ClariDAO: On-Chain DAO Governance

ClariDAO is a smart contract implementation of a decentralized autonomous organization (DAO) with robust proposal and voting mechanisms built on the Clarity language for the Stacks blockchain.

## Overview

ClariDAO provides a comprehensive framework for decentralized governance, enabling token holders to create and vote on proposals, delegate voting power, and execute approved decisions in a transparent and secure manner.

## Features

- **Token-based Governance**: Decisions weighted by token holdings
- **Proposal System**: Create, track, and execute on-chain proposals
- **Voting Mechanism**: Secure voting with quorum and approval thresholds
- **Delegation System**: Time-locked delegation of voting power
- **Treasury Management**: Built-in DAO treasury functions

## Technical Implementation

The ClariDAO contract implements several core components:

### Token System

- Native DAO token for governance voting
- View token balances via `get-token-balance`
- Token minting controlled by contract owner

### Proposal Creation & Management

- Create proposals with `create-proposal` function
- Each proposal includes title, description, action data, and execution delay
- Proposals require minimum token holdings to create (100 tokens)
- View proposals with `get-proposal` function

### Voting Mechanism

- One token equals one vote
- Configurable voting period (default: 144 blocks, ~24 hours)
- Vote tracking prevents double-voting
- Quorum threshold ensures minimum participation (default: 500 tokens)
- Approval threshold requires supermajority consensus (default: 66.7%)

### Proposal Finalization

- `finalize-proposal` function evaluates voting results
- Automatic status update based on voting outcome
- Ensures voting period has ended and quorum was reached

### Delegation System

- Delegate voting power to other addresses
- Time-locked delegation prevents frequent changes
- Tracking of delegation relationships
- Protection against delegation loops

## Contract Functions

### Core Functions

```clarity
(define-public (initialize-dao))
(define-public (mint-tokens (amount uint) (recipient principal)))
(define-read-only (get-token-balance (account principal)))
(define-public (create-proposal (title (string-ascii 100)) (description (string-utf8 500)) (action-data (optional (buff 1024))) (execution-delay uint)))
(define-read-only (get-proposal (proposal-id uint)))
(define-public (vote (proposal-id uint) (support bool)))
(define-public (finalize-proposal (proposal-id uint)))
(define-public (delegate-voting-power (delegate-to principal) (amount uint) (lock-period uint)))
```

### Constants & Error Codes

- `ERR-NOT-AUTHORIZED (err u100)`: Function caller is not authorized
- `ERR-PROPOSAL-DOES-NOT-EXIST (err u101)`: The requested proposal doesn't exist
- `ERR-ALREADY-VOTED (err u102)`: User has already voted on this proposal
- `ERR-VOTING-CLOSED (err u103)`: The voting period has ended
- `ERR-INSUFFICIENT-TOKEN-BALANCE (err u104)`: User lacks required token balance
- `ERR-PROPOSAL-NOT-APPROVED (err u105)`: Attempting to execute a rejected proposal
- `ERR-QUORUM-NOT-REACHED (err u106)`: Proposal didn't reach minimum participation

## Installation

To deploy ClariDAO to a Stacks blockchain:

1. Install the [Clarinet](https://github.com/hirosystems/clarinet) development environment
2. Clone this repository
3. Deploy using Clarinet or the Stacks CLI tools:

```bash
# Using Clarinet
clarinet deploy

# Using Stacks CLI
stacks deploy claridao.clar --network mainnet
```

## Usage Examples

### Creating a Proposal

```clarity
(contract-call? .claridao create-proposal 
  "Treasury Allocation" 
  "Allocate 1000 tokens to the community development fund" 
  none 
  u100)
```

### Voting on a Proposal

```clarity
;; Vote in favor of proposal with ID 0
(contract-call? .claridao vote u0 true)

;; Vote against proposal with ID 0
(contract-call? .claridao vote u0 false)
```

### Finalizing a Proposal

```clarity
(contract-call? .claridao finalize-proposal u0)
```

### Delegating Voting Power

```clarity
;; Delegate 500 tokens for 100 blocks
(contract-call? .claridao delegate-voting-power 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u500 u100)
```

## Configuration

The following parameters can be adjusted during contract deployment:

- `VOTING_PERIOD_BLOCKS`: Duration of the voting period in blocks
- `quorum-threshold`: Minimum total votes required for valid proposals
- `approval-threshold`: Percentage of "for" votes required for approval (in thousandths)

## Security Considerations

- Time-locked delegation prevents vote manipulation
- Quorum requirements ensure sufficient participation
- Token-gated proposal creation prevents spam
- Voting power equals token holdings to align incentives

## Development Roadmap

- [ ] Multi-signature proposal execution
- [ ] Tiered voting rights
- [ ] Proposal templates
- [ ] Integration with token swaps and DeFi protocols
- [ ] Improved UI/UX for governance dashboard

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2025 ClariDAO Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Acknowledgments

* [Clarity Language Documentation](https://docs.stacks.co/clarity/introduction)
* [Stacks Blockchain](https://www.stacks.co/)
* All contributors and community members
