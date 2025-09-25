# Code Forge - Decentralized Software Development Platform

A comprehensive smart contract built on the Stacks blockchain using Clarity for managing decentralized software development projects with integrated quality assurance processes.

## Overview

Code Forge is a decentralized platform that connects clients with developers and quality assurance reviewers to ensure high-quality software delivery. The platform uses smart contracts to handle project management, payments, escrow, and reputation tracking automatically.

## Key Features

### 🎯 Project Management
- Create projects with detailed specifications and budgets
- Automatic escrow system for secure payments
- Developer application and selection process
- Milestone-based project tracking
- Comprehensive status management

### 🔍 Quality Assurance
- Dedicated QA reviewer assignment
- Multi-stage review process
- Quality scoring system (1-5 scale)
- Revision request capability
- QA compensation from platform fees

### 💰 Secure Payment System
- Automatic budget escrow on project creation
- Platform fee collection (default 5%, configurable)
- Fair compensation distribution
- Refund system for cancelled projects
- Transparent fee structure

### ⭐ Reputation System
- Developer performance tracking
- QA reviewer accuracy metrics
- Verification system for trusted participants
- Historical project completion rates
- Rating-based reputation scores

## Project Lifecycle

```
1. Open → 2. In Progress → 3. Under Review → 4. Completed
    ↓                                           ↑
5. Cancelled                            6. Revision Needed
```

### Status Definitions
- **Open (0)**: Project created, accepting developer applications
- **In Progress (1)**: Developer assigned and working
- **Under Review (2)**: Work submitted, awaiting QA review
- **Revision Needed (3)**: QA requested changes
- **Completed (4)**: Project finished and approved
- **Cancelled (5)**: Project cancelled by client

## Smart Contract Functions

### Public Functions

#### Project Management
- `create-project`: Create a new project with escrow
- `apply-to-project`: Submit application to work on a project
- `assign-developer`: Assign chosen developer to project
- `assign-qa-reviewer`: Assign QA reviewer to project
- `cancel-project`: Cancel project and refund client

#### Development Workflow
- `submit-for-review`: Developer submits completed work
- `qa-review`: QA reviewer approves or requests revisions
- `accept-and-pay`: Client accepts work and releases payment

#### Administration
- `set-platform-fee`: Update platform fee percentage (owner only)
- `verify-developer`: Verify developer profile (owner only)
- `verify-qa-reviewer`: Verify QA reviewer profile (owner only)

### Read-Only Functions
- `get-project`: Retrieve project details
- `get-developer-profile`: Get developer reputation data
- `get-qa-profile`: Get QA reviewer profile
- `get-project-application`: View application details
- `get-next-project-id`: Get next available project ID

## Data Structures

### Project Data
```clarity
{
  client: principal,
  developer: (optional principal),
  qa-reviewer: (optional principal),
  title: (string-ascii 100),
  description: (string-ascii 500),
  budget: uint,
  status: uint,
  created-at: uint,
  deadline: uint,
  client-satisfaction: (optional uint),
  qa-score: (optional uint)
}
```

### Developer Profile
```clarity
{
  reputation-score: uint,
  completed-projects: uint,
  average-rating: uint,
  is-verified: bool
}
```

### QA Reviewer Profile
```clarity
{
  reputation-score: uint,
  reviews-completed: uint,
  average-accuracy: uint,
  is-verified: bool
}
```

## Usage Examples

### Creating a Project
```clarity
(contract-call? .code-forge create-project
  "Build Mobile App"
  "Need a React Native app for iOS and Android"
  u1000000  ;; 1 STX budget
  u144      ;; 1 day deadline (144 blocks)
)
```

### Applying to a Project
```clarity
(contract-call? .code-forge apply-to-project
  u1
  "Experienced React Native developer with 5+ years"
  u288      ;; 2 days proposed timeline
)
```

### QA Review
```clarity
(contract-call? .code-forge qa-review
  u1
  true      ;; approved
  u4        ;; QA score (1-5)
)
```

## Error Codes

- `u100`: Owner only operation
- `u101`: Project/resource not found
- `u102`: Unauthorized access
- `u103`: Invalid status or parameter
- `u104`: Insufficient payment
- `u105`: Project already completed

## Security Features

### Access Control
- Role-based permissions for all operations
- Client, developer, and QA reviewer authorization checks
- Contract owner administrative privileges

### Input Validation
- Parameter type and range validation
- Status transition verification
- Rating score bounds checking

### Financial Security
- Secure escrow system
- Protected fund transfers
- Automatic fee calculations
- Refund mechanisms

## Deployment

### Prerequisites
- Clarinet CLI installed
- Stacks blockchain testnet/mainnet access
- STX tokens for deployment

### Installation
```bash
# Clone the project
git clone <repository-url>
cd code-forge

# Check contract syntax
clarinet check

# Run tests
npm install
npm test

# Deploy to testnet
clarinet deploy --testnet
```

### Configuration
- Set platform fee percentage (default: 5%)
- Configure admin privileges
- Set up initial verified developers/QA reviewers

## Testing

The contract includes comprehensive test coverage for:
- Project creation and management
- Developer application process
- QA review workflow
- Payment and escrow functionality
- Reputation system updates
- Error handling and edge cases

```bash
# Run all tests
npm test

# Run specific test file
npm test -- --testNamePattern="project-creation"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or contributions:
- Create an issue on GitHub
- Join our Discord community
- Check the documentation wiki
