# CrisisResponse

CrisisResponse is a rapid decision-making platform for emergency management and disaster response coordination built on the Stacks blockchain using Clarity smart contracts.

## Description

This decentralized platform enables emergency responders to create incidents, propose decisions, vote on responses, and coordinate resource allocation during crisis situations. The system implements role-based access control to ensure proper authorization and maintains transparency through blockchain-based voting and decision tracking.

## Features

- **Incident Management**: Create, track, and update emergency incidents with severity levels and location data
- **Role-Based Access Control**: Three-tier role system (Admin, Commander, Responder) with appropriate permissions
- **Democratic Decision Making**: Propose decisions for incidents with time-bound voting mechanisms
- **Resource Allocation**: Track and allocate emergency resources with inventory management
- **Command Assignment**: Assign commanders to incidents for coordinated response
- **Transparent Voting**: Blockchain-based voting system with vote tracking and finalization
- **Status Tracking**: Real-time incident status updates (Active, Resolved, Escalated)

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Contract Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

### Contract Architecture

The smart contract includes the following key components:

- **Data Maps**: Incidents, decisions, resource allocations, votes, user roles, and resource inventory
- **Role Constants**: Admin (1), Commander (2), Responder (3)
- **Status Constants**: Active (1), Resolved (2), Escalated (3)
- **Decision States**: Pending (1), Approved (2), Rejected (3)

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) (version 14 or higher)
- [Stacks CLI](https://docs.stacks.co/build-apps/references/stacks-cli)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd CrisisResponse
```

2. Navigate to the contract directory:
```bash
cd CrisisResponse_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

5. Run tests:
```bash
clarinet test
```

## Usage Examples

### Initialize the Contract

```clarity
;; Initialize contract (automatically assigns admin role to deployer)
(contract-call? .CrisisResponse initialize)
```

### Role Management

```clarity
;; Assign commander role to a user (admin only)
(contract-call? .CrisisResponse assign-role 'SP1EXAMPLE... u2)

;; Assign responder role to a user (admin only)
(contract-call? .CrisisResponse assign-role 'SP2EXAMPLE... u3)

;; Check user role
(contract-call? .CrisisResponse get-user-role 'SP1EXAMPLE...)
```

### Incident Management

```clarity
;; Create a new incident (responder+ required)
(contract-call? .CrisisResponse create-incident
    "Earthquake Response"
    "Magnitude 7.2 earthquake in downtown area requiring immediate response"
    u5
    "Downtown District")

;; Assign commander to incident (admin only)
(contract-call? .CrisisResponse assign-commander u1 'SP1COMMANDER...)

;; Update incident status (admin or assigned commander)
(contract-call? .CrisisResponse update-incident-status u1 u2)
```

### Decision Making

```clarity
;; Propose a decision (commander+ required)
(contract-call? .CrisisResponse propose-decision
    u1
    "Evacuation Order"
    "Mandatory evacuation of 5-block radius around epicenter"
    u144) ;; 144 blocks voting period

;; Vote on decision (responder+ required)
(contract-call? .CrisisResponse vote-on-decision u1 true)

;; Finalize decision after voting period
(contract-call? .CrisisResponse finalize-decision u1)
```

### Resource Management

```clarity
;; Add resources to inventory (admin only)
(contract-call? .CrisisResponse add-resources "medical-supplies" u100)

;; Allocate resources to incident (commander+ required)
(contract-call? .CrisisResponse allocate-resources u1 "medical-supplies" u25)

;; Check resource availability
(contract-call? .CrisisResponse get-resource-availability "medical-supplies")
```

## Contract Functions Documentation

### Public Functions

#### Administrative Functions
- `initialize()` - Initialize contract with admin role for deployer
- `assign-role(user, role)` - Assign roles to users (admin only)
- `add-resources(resource-type, quantity)` - Add resources to inventory (admin only)

#### Incident Management
- `create-incident(title, description, severity, location)` - Create new emergency incident
- `assign-commander(incident-id, commander)` - Assign commander to incident (admin only)
- `update-incident-status(incident-id, new-status)` - Update incident status

#### Decision Management
- `propose-decision(incident-id, title, description, voting-period)` - Propose decision for incident
- `vote-on-decision(decision-id, vote)` - Vote on proposed decision
- `finalize-decision(decision-id)` - Finalize decision after voting period

#### Resource Allocation
- `allocate-resources(incident-id, resource-type, quantity)` - Allocate resources to incident

### Read-Only Functions

- `get-user-role(user)` - Get user's role level
- `get-incident(incident-id)` - Get incident details
- `get-decision(decision-id)` - Get decision details
- `get-resource-availability(resource-type)` - Get available resource quantity
- `has-voted(decision-id, voter)` - Check if user has voted on decision
- `get-vote(decision-id, voter)` - Get specific vote details
- `get-incident-counter()` - Get current incident counter
- `get-decision-counter()` - Get current decision counter

### Error Codes

- `ERR-NOT-AUTHORIZED (100)` - Insufficient permissions
- `ERR-INCIDENT-NOT-FOUND (101)` - Incident does not exist
- `ERR-DECISION-NOT-FOUND (102)` - Decision does not exist
- `ERR-ALREADY-VOTED (103)` - User has already voted
- `ERR-VOTING-CLOSED (104)` - Voting period has ended
- `ERR-INVALID-STATUS (105)` - Invalid status value
- `ERR-INSUFFICIENT-RESOURCES (106)` - Not enough resources available

## Deployment Guide

### Local Development (Clarinet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

3. Test contract functions in the console

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Notes

### Access Control
- Role-based permissions ensure only authorized users can perform critical operations
- Admin role has highest privileges and should be carefully managed
- Commander role can propose decisions and allocate resources
- Responder role can create incidents and vote on decisions

### Voting Mechanism
- Time-bound voting prevents indefinite decision delays
- One vote per user per decision prevents vote manipulation
- Decisions require majority approval for execution
- Vote history is permanently recorded on blockchain

### Resource Management
- Resource allocation checks available inventory before allocation
- Only commanders and admins can allocate resources
- Resource additions require admin privileges

### Best Practices
- Initialize contract immediately after deployment
- Carefully manage admin role assignments
- Set appropriate voting periods for decision urgency
- Monitor resource inventory levels
- Regular audit of role assignments and permissions

### Known Limitations
- No built-in mechanism for role revocation
- Resource allocations cannot be undone once committed
- Voting periods cannot be extended once set
- No emergency override mechanism for critical decisions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass with `clarinet test`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.