# Dojo Tic-Tac-Toe Game

A minimal on-chain Tic-Tac-Toe game built with Dojo on StarkNet.

## Overview

This project demonstrates a simple turn-based game implementation using the Dojo framework. Players can create games, make moves, and the smart contract automatically detects winners.

## Features

- **Create Game**: Start a new Tic-Tac-Toe game with another player
- **Make Move**: Place your mark (X or O) on the board
- **Auto Winner Detection**: Automatically detects wins, draws, and validates moves
- **On-chain State**: All game state is stored on StarkNet

## Prerequisites

Before you begin, ensure you have the following installed:

- [Rust](https://www.rust-lang.org/tools/install) (latest stable version)
- [Cairo](https://book.cairo-lang.org/ch01-01-installation.html) 
- [Dojo](https://book.dojoengine.org/getting-started/quick-start.html) - Install with:
  ```bash
  curl -L https://install.dojoengine.org | bash
  dojoup
  ```

After installing Dojo, you'll have access to:
- `sozo` - Dojo project manager and migration tool
- `katana` - Local StarkNet node for development
- `torii` - Indexer for querying world state

## Project Structure

```
dojo-game/
├── Scarb.toml              # Project configuration and dependencies
├── manifest_dev.toml       # Indexer configuration for torii
├── src/
│   ├── lib.cairo          # Main library file
│   ├── models/
│   │   └── game.cairo     # Game and Board models
│   ├── models.cairo       # Models module
│   ├── systems/
│   │   └── actions.cairo  # Game logic (create_game, make_move)
│   └── systems.cairo      # Systems module
└── README.md
```

## Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd dojo-game
   ```

2. **Build the project**:
   ```bash
   sozo build
   ```

## Running the Game

### 1. Start Katana (Local StarkNet Node)

In a terminal window, start the local development node:

```bash
katana --disable-fee
```

This starts a local StarkNet node at `http://localhost:5050` with:
- Pre-funded accounts for testing
- Disabled fees for easier development
- Fast block times

Keep this terminal running.

### 2. Migrate (Deploy) the Contracts

In a new terminal window, deploy your contracts to the local Katana node:

```bash
sozo migrate apply
```

This will:
- Compile your Cairo contracts
- Deploy the world contract
- Deploy your models (Game, Board)
- Deploy your systems (actions)
- Generate migration artifacts

### 3. Start Torii (Indexer)

In a third terminal window, start the indexer to query game state:

```bash
torii --world <WORLD_ADDRESS>
```

Replace `<WORLD_ADDRESS>` with the world contract address from the migration output.

The indexer will:
- Listen for events from your world
- Index all game state
- Provide GraphQL and gRPC APIs at `http://localhost:8080`

### 4. Interact with the Game

You can interact with the game using `sozo execute`:

**Create a new game**:
```bash
sozo execute actions create_game --calldata 0x517ececd29116499f4a1b64b094da79ba08dfd54a3edaa316134c41f8160973
```
- The calldata is the address of player two

**Make a move**:
```bash
sozo execute actions make_move --calldata <game_id>,<position>
```
- `game_id`: The ID returned from create_game
- `position`: Cell position (0-8, where 0 is top-left, 8 is bottom-right)

Example:
```bash
sozo execute actions make_move --calldata 1,4  # Place mark in center
```

**Query game state**:
```bash
sozo model get Game <game_id>
sozo model get Board <game_id>
```

## Game Rules

- The board has 9 positions (0-8) arranged in a 3x3 grid:
  ```
  0 | 1 | 2
  ---------
  3 | 4 | 5
  ---------
  6 | 7 | 8
  ```
- Player one gets X (mark value: 1)
- Player two gets O (mark value: 2)
- Players alternate turns
- First to get 3 in a row (horizontal, vertical, or diagonal) wins
- If all cells are filled with no winner, the game is a draw

## Development

### Building

```bash
sozo build
```

### Testing

```bash
sozo test
```

### Clean Build

```bash
sozo clean
```

## Indexer API

Once Torii is running, you can query the game state via GraphQL at `http://localhost:8080/graphql`.

Example query:
```graphql
{
  gameModels {
    edges {
      node {
        game_id
        player_one
        player_two
        winner
        current_turn
        is_active
      }
    }
  }
}
```

## Troubleshooting

- **"Command not found: sozo/katana/torii"**: Make sure Dojo is properly installed with `dojoup`
- **Connection refused**: Ensure Katana is running on `http://localhost:5050`
- **Migration fails**: Make sure Katana is running and the RPC URL in Scarb.toml is correct
- **Transaction fails**: Check that you're using the correct account address and the game is in a valid state

## Resources

- [Dojo Book](https://book.dojoengine.org/) - Official Dojo documentation
- [Cairo Book](https://book.cairo-lang.org/) - Learn Cairo programming language
- [StarkNet Docs](https://docs.starknet.io/) - StarkNet documentation

## License

MIT